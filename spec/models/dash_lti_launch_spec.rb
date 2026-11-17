# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(DashLtiLaunch) do
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'dash-spec', institution_guid: 'spec-institution') }
  let(:tool) { RailsLti2Provider::Tool.create!(uuid: 'dash-spec', shared_secret: 'secret', lti_version: 'LTI-1p0', tenant: tenant, app_settings: {}) }
  let(:context) do
    LtiContext.create!(
      tool: tool, app: 'rooms', rooms_handler: Digest::SHA1.hexdigest('roomsdash-speccourse-1'), oauth_consumer_key: 'dash-spec',
      context_id: 'course-1', context_title: 'Calculus I', resource_link_id: 'link-1', last_launch_at: Time.current
    )
  end
  let(:dash_launch) { described_class.from_context(context).tap { |launch| launch.name = 'Jane Doe' } }

  before do
    BbbConfig.create!(tool: tool, url: 'https://bbb.example.com/bigbluebutton/', secret: 'bbb-secret')
    %w[rooms worka].each { |app| Doorkeeper::Application.create!(name: app, redirect_uri: "https://#{app}.example.com/#{app}/auth/bbbltibroker/callback") }
  end

  it 'opens the room of the context it came from' do
    expect(dash_launch.rooms_handler).to(eq(context.rooms_handler))
  end

  it 'opens another room when the course changes' do
    dash_launch.context_id = 'dash-test-1'
    expect(dash_launch.rooms_handler).not_to(eq(context.rooms_handler))
  end

  it 'builds the launch the app expects, with the tool configs and the dash marker' do
    expect(dash_launch.message).to(include(
                                        'user_id' => 'dash-jane-doe', 'roles' => 'Instructor', 'context_id' => 'course-1',
                                        'lis_person_name_full' => 'Jane Doe', 'lis_person_name_given' => 'Jane', 'lis_person_name_family' => 'Doe'
                                      ))
    expect(dash_launch.message['custom_params']).to(include(
                                                         'oauth_consumer_key' => 'dash-spec', 'institution_guid' => 'spec-institution',
                                                         'custom_dash_launch' => 'jane-doe', 'bbb' => include('url' => 'https://bbb.example.com/bigbluebutton/')
                                                       ))
    expect(dash_launch.message).not_to(have_key('lis_person_contact_email_primary'))
  end

  it 'refuses a name with nothing to identify, a role the app does not know, a missing tool and an unknown app' do
    dash_launch.assign_attributes(name: '!!!', lti_role: 'Administrator', tool_id: 0, app: 'unknown')
    expect(dash_launch).not_to(be_valid)
    expect(dash_launch.errors.attribute_names).to(contain_exactly(:operator, :lti_role, :tool_id, :app))
    expect(dash_launch.errors.full_messages).to(include('Operator needs letters or digits in the name', 'App must be an app registered in the broker'))
    expect(dash_launch.errors.full_messages.join).not_to(include('translation missing'))
  end

  it 'opens a Rooms room by its handler, with the course and resource link from the history' do
    launch = described_class.new(tool_id: tool.id, name: 'Jane Doe', handler: " #{context.rooms_handler} ")
    expect(launch).to(be_valid)
    expect(launch).to(have_attributes(context_id: 'course-1', context_title: 'Calculus I', resource_link_id: 'link-1', rooms_handler: context.rooms_handler))
  end

  it 'refuses a handler of another tool, saying which tool it belongs to' do
    other_tool = RailsLti2Provider::Tool.create!(uuid: 'dash-other', shared_secret: 'secret', lti_version: 'LTI-1p0', tenant: tenant, app_settings: {})
    launch = described_class.new(tool_id: other_tool.id, name: 'Jane Doe', handler: context.rooms_handler)
    expect(launch).not_to(be_valid)
    expect(launch.errors[:handler]).to(eq(['belongs to tool dash-spec, not this one']))
  end

  it 'refuses a handler with no launch in the history' do
    launch = described_class.new(tool_id: tool.id, name: 'Jane Doe', handler: 'unknown')
    expect(launch).not_to(be_valid)
    expect(launch.errors[:handler]).to(eq(['has no Rooms launch recorded for this tool']))
  end

  it 'carries the LTI version of the tool' do
    tool.update!(lti_version: '1.3.0')
    expect(dash_launch.message['lti_version']).to(eq('1.3.0'))
  end

  it 'launches into another app with that app configs and no room to predict' do
    WorkaAppConfig.create!(tool: tool, saas_world_url: 'https://worka.example.com/world')
    dash_launch.app = 'worka'
    expect(dash_launch.message['custom_params']).to(include('saas_world_url' => 'https://worka.example.com/world'))
    expect(dash_launch.rooms_handler).to(be_nil)

    dash_launch.launch!(ip: '10.0.0.1')
    expect(DashLaunchLog.sole).to(have_attributes(app: 'worka', rooms_handler: nil))
  end

  describe '#launch!' do
    it 'creates the launch, the user Doorkeeper authorizes and the access record' do
      launch = dash_launch.launch!(ip: '10.0.0.1')

      expect(launch.tool).to(eq(tool))
      expect(JSON.parse(launch[:message])).to(eq(dash_launch.message))
      expect(User.find(launch.user_id)).to(have_attributes(context: 'dash', uid: 'dash-jane-doe', first_name: 'Jane', last_name: 'Doe'))
      expect(DashLaunchLog.sole).to(have_attributes(operator: 'jane-doe', tool: tool, app: 'rooms', rooms_handler: context.rooms_handler, role: 'Instructor', ip: '10.0.0.1'))
    end

    it 'reuses the user of the same name' do
      2.times { dash_launch.launch!(ip: '10.0.0.1') }
      expect(User.where(context: 'dash').count).to(eq(1))
    end
  end
end
