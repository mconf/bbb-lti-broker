# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(DashLtiLaunch) do
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'dash-spec', institution_guid: 'spec-institution') }
  let(:tool) { RailsLti2Provider::Tool.create!(uuid: 'dash-spec', shared_secret: 'secret', lti_version: 'LTI-1p0', tenant: tenant, app_settings: {}) }
  let(:context) do
    LtiContext.create!(
      tool: tool, app: 'rooms', handler: Digest::SHA1.hexdigest('roomsdash-speccourse-1'), oauth_consumer_key: 'dash-spec',
      context_id: 'course-1', context_title: 'Calculus I', resource_link_id: 'link-1', last_launch_at: Time.current
    )
  end
  let(:dash_launch) { described_class.from_context(context).tap { |launch| launch.operator = 'jane.doe' } }

  before { BbbConfig.create!(tool: tool, url: 'https://bbb.example.com/bigbluebutton/', secret: 'bbb-secret') }

  it 'opens the room of the context it came from' do
    expect(dash_launch.handler).to(eq(context.handler))
  end

  it 'opens another room when the course changes' do
    dash_launch.context_id = 'dash-test-1'
    expect(dash_launch.handler).not_to(eq(context.handler))
  end

  it 'builds the launch the app expects, with the tool configs and the dash marker' do
    expect(dash_launch.message).to(include(
                                        'user_id' => 'dash-jane.doe', 'roles' => 'Instructor', 'context_id' => 'course-1',
                                        'lis_person_name_full' => 'Suporte (jane.doe)'
                                      ))
    expect(dash_launch.message['custom_params']).to(include(
                                                         'oauth_consumer_key' => 'dash-spec', 'institution_guid' => 'spec-institution',
                                                         'custom_dash_launch' => 'jane.doe', 'bbb' => include('url' => 'https://bbb.example.com/bigbluebutton/')
                                                       ))
    expect(dash_launch.message).not_to(have_key('lis_person_contact_email_primary'))
  end

  it 'refuses an operator that is not a plain slug, a role the app does not know and a missing tool' do
    dash_launch.assign_attributes(operator: 'Jane Doe', lti_role: 'Administrator', tool_id: 0)
    expect(dash_launch).not_to(be_valid)
    expect(dash_launch.errors.attribute_names).to(contain_exactly(:operator, :lti_role, :tool_id))
  end

  describe '#launch!' do
    it 'creates the launch, the user Doorkeeper authorizes and the access record' do
      launch = dash_launch.launch!(ip: '10.0.0.1')

      expect(launch.tool).to(eq(tool))
      expect(JSON.parse(launch[:message])).to(eq(dash_launch.message))
      expect(User.find(launch.user_id)).to(have_attributes(context: 'dash', uid: 'dash-jane.doe'))
      expect(DashLaunchLog.sole).to(have_attributes(operator: 'jane.doe', kind: 'launch', tool: tool, handler: context.handler, role: 'Instructor', ip: '10.0.0.1'))
    end

    it 'reuses the user of the same operator' do
      2.times { dash_launch.launch!(ip: '10.0.0.1') }
      expect(User.where(context: 'dash').count).to(eq(1))
    end
  end
end
