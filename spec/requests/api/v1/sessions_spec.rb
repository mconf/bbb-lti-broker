# frozen_string_literal: true

require 'rails_helper'

# The format MessageController stores the launch in is covered by spec/requests/lti13_launch_spec.rb;
# these cover the formats it no longer produces and the claims a platform may leave out
RSpec.describe('Api::V1::Sessions', type: :request) do
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'sessions-spec') }
  let(:tool) do
    RailsLti2Provider::Tool.create!(
      uuid: 'sessions-spec', shared_secret: 'sessions-spec', tool_settings: { client_id: 'sessions-spec' }.to_json,
      app_settings: {}, lti_version: '1.3.0', tenant: tenant
    )
  end
  let(:claims) { lti13_claims(roles: [LtiHelpers::LEARNER, 'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student']) }
  let(:custom_params) { { 'oauth_consumer_key' => 'sessions-spec', 'institution_guid' => 'spec-institution' } }

  before { stub_doorkeeper_token }

  def create_launch(message)
    tool.lti_launches.create!(nonce: 'spec-nonce', message: message.to_json)
  end

  def session_message
    get '/api/v1/sessions/spec-nonce'
    expect(response).to(have_http_status(:success))
    JSON.parse(response.body)['message']
  end

  describe 'GET /api/v1/sessions/:token' do
    it 'maps the claims of older launches, wrapped in unknown_params' do
      create_launch('unknown_params' => claims, 'custom_params' => custom_params)
      expect(session_message).to(include(
                                   'user_id' => 'user-1',
                                   'lis_person_name_full' => 'Jane Doe',
                                   'lis_person_contact_email_primary' => 'jane@example.com',
                                   'roles' => "#{LtiHelpers::LEARNER},http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student",
                                   'context_id' => 'course-1',
                                   'context_title' => 'Calculus I',
                                   'context_label' => 'CALC1',
                                   'resource_link_id' => 'link-1',
                                   'tool_consumer_instance_guid' => 'platform-guid',
                                   'launch_presentation_locale' => 'pt_br'
                                 ))
    end

    # launch_presentation and tool_platform are optional in LTI 1.3
    it 'leaves out the parameters of the claims the platform did not send' do
      optional = %w[launch_presentation tool_platform].map { |claim| "https://purl.imsglobal.org/spec/lti/claim/#{claim}" }
      create_launch(claims.except(*optional).merge('custom_params' => custom_params))
      message = session_message
      expect(message).to(include('user_id' => 'user-1', 'context_title' => 'Calculus I'))
      expect(message).not_to(include('launch_presentation_locale', 'tool_consumer_instance_guid'))
    end

    # LTI 1.0 launches already come with the LTI 1.1 parameters, so the claims are not mapped
    it 'hands an LTI 1.0 launch over unchanged' do
      message = {
        'user_id' => '60',
        'roles' => 'Learner',
        'context_id' => '7',
        'context_title' => 'Calculus I',
        'lti_version' => 'LTI-1p0',
        'custom_params' => custom_params,
      }
      create_launch(message)
      expect(session_message).to(eq(message))
    end
  end
end
