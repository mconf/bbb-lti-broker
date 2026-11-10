# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(SupportLaunch) do
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'support-spec', institution_guid: 'spec-institution') }
  let(:tool) { RailsLti2Provider::Tool.create!(uuid: 'support-spec', shared_secret: 'secret', lti_version: 'LTI-1p0', tenant: tenant, app_settings: {}) }
  let(:context) do
    LtiContext.create!(
      tool: tool, app: 'rooms', handler: Digest::SHA1.hexdigest('roomssupport-speccourse-1'), oauth_consumer_key: 'support-spec',
      context_id: 'course-1', context_title: 'Calculus I', resource_link_id: 'link-1', last_launch_at: Time.current
    )
  end
  let(:support_launch) { described_class.from_context(context).tap { |launch| launch.operator = 'jane.doe' } }

  before { BbbConfig.create!(tool: tool, url: 'https://bbb.example.com/bigbluebutton/', secret: 'bbb-secret') }

  it 'opens the room of the context it came from' do
    expect(support_launch.handler).to(eq(context.handler))
  end

  it 'opens another room when the course changes' do
    support_launch.context_id = 'support-test-1'
    expect(support_launch.handler).not_to(eq(context.handler))
  end

  it 'builds the launch the app expects, with the tool configs and the support marker' do
    expect(support_launch.message).to(include(
                                        'user_id' => 'elos-support-jane.doe', 'roles' => 'Instructor', 'context_id' => 'course-1',
                                        'lis_person_name_full' => 'Suporte (jane.doe)'
                                      ))
    expect(support_launch.message['custom_params']).to(include(
                                                         'oauth_consumer_key' => 'support-spec', 'institution_guid' => 'spec-institution',
                                                         'custom_elos_support' => 'jane.doe', 'bbb' => include('url' => 'https://bbb.example.com/bigbluebutton/')
                                                       ))
    expect(support_launch.message).not_to(have_key('lis_person_contact_email_primary'))
  end

  it 'refuses an operator that is not a plain slug, a role the app does not know and a missing tool' do
    support_launch.assign_attributes(operator: 'Jane Doe', lti_role: 'Administrator', tool_id: 0)
    expect(support_launch).not_to(be_valid)
    expect(support_launch.errors.attribute_names).to(contain_exactly(:operator, :lti_role, :tool_id))
  end

  describe '#launch!' do
    it 'creates the launch, the user Doorkeeper authorizes and the access record' do
      launch = support_launch.launch!(ip: '10.0.0.1')

      expect(launch.tool).to(eq(tool))
      expect(JSON.parse(launch[:message])).to(eq(support_launch.message))
      expect(User.find(launch.user_id)).to(have_attributes(context: 'elos-support', uid: 'elos-support-jane.doe'))
      expect(SupportAccess.sole).to(have_attributes(operator: 'jane.doe', kind: 'launch', tool: tool, handler: context.handler, role: 'Instructor', ip: '10.0.0.1'))
    end

    it 'reuses the user of the same operator' do
      2.times { support_launch.launch!(ip: '10.0.0.1') }
      expect(User.where(context: 'elos-support').count).to(eq(1))
    end
  end
end
