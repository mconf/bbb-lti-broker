# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Api::V1::Sessions', type: :request) do
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'sessions-spec') }
  let(:tool) do
    RailsLti2Provider::Tool.create!(
      uuid: 'sessions-spec', shared_secret: 'sessions-spec', tool_settings: { client_id: 'sessions-spec' }.to_json,
      app_settings: {}, lti_version: '1.3.0', tenant: tenant
    )
  end
  let(:claims) do
    {
      'sub' => 'user-1',
      'name' => 'Jane Doe',
      'given_name' => 'Jane',
      'family_name' => 'Doe',
      'email' => 'jane@example.com',
      'https://purl.imsglobal.org/spec/lti/claim/message_type' => 'LtiResourceLinkRequest',
      'https://purl.imsglobal.org/spec/lti/claim/version' => '1.3.0',
      'https://purl.imsglobal.org/spec/lti/claim/roles' => [
        'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner',
        'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student',
      ],
      'https://purl.imsglobal.org/spec/lti/claim/context' => { 'id' => 'course-1', 'label' => 'CALC1', 'title' => 'Calculus I' },
      'https://purl.imsglobal.org/spec/lti/claim/resource_link' => { 'id' => 'link-1', 'title' => 'Class room' },
      'https://purl.imsglobal.org/spec/lti/claim/tool_platform' => { 'guid' => 'platform-guid', 'url' => 'https://lms.example.com' },
      'https://purl.imsglobal.org/spec/lti/claim/launch_presentation' => { 'locale' => 'pt_br' },
    }
  end
  let(:custom_params) { { 'oauth_consumer_key' => 'sessions-spec', 'institution_guid' => 'spec-institution' } }

  # Rooms authenticates with a Doorkeeper client token; any token is accepted here
  before do
    allow_any_instance_of(Api::V1::SessionsController).to(receive(:doorkeeper_token).and_return(instance_double(Doorkeeper::AccessToken, acceptable?: true)))
  end

  def create_launch(message)
    tool.lti_launches.create!(nonce: 'spec-nonce', message: message.to_json)
  end

  # How MessageController#add_custom_params_to_launch_message stores the 1.3 launch: post_params puts the claims at the root
  def flat_message(claims)
    claims.merge('custom_params' => custom_params)
  end

  def session_message
    get '/api/v1/sessions/spec-nonce'
    expect(response).to(have_http_status(:success))
    JSON.parse(response.body)['message']
  end

  shared_examples 'a standardized 1.3 message' do
    it 'maps the claims to the LTI 1.1 parameters' do
      expect(session_message).to(include(
                                   'user_id' => 'user-1',
                                   'lis_person_name_full' => 'Jane Doe',
                                   'lis_person_contact_email_primary' => 'jane@example.com',
                                   'roles' => 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner,http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student',
                                   'context_id' => 'course-1',
                                   'context_title' => 'Calculus I',
                                   'context_label' => 'CALC1',
                                   'resource_link_id' => 'link-1',
                                   'tool_consumer_instance_guid' => 'platform-guid',
                                   'launch_presentation_locale' => 'pt_br'
                                 ))
    end
  end

  describe 'GET /api/v1/sessions/:token' do
    context 'with the claims at the root of the message' do
      before { create_launch(flat_message(claims)) }

      it_behaves_like 'a standardized 1.3 message'

      # The apps read the tenant and app configs from custom_params, without the custom_ prefix
      it 'keeps the custom params as they were stored' do
        expect(session_message['custom_params']).to(eq(custom_params))
      end
    end

    context 'with the claims wrapped in unknown_params, as older launches were stored' do
      before { create_launch('unknown_params' => claims, 'custom_params' => custom_params) }

      it_behaves_like 'a standardized 1.3 message'
    end

    # launch_presentation and tool_platform are optional in LTI 1.3
    it 'leaves out the parameters of the claims the platform did not send' do
      create_launch(flat_message(claims.except('https://purl.imsglobal.org/spec/lti/claim/launch_presentation', 'https://purl.imsglobal.org/spec/lti/claim/tool_platform')))
      message = session_message
      expect(message).to(include('user_id' => 'user-1', 'context_title' => 'Calculus I'))
      expect(message).not_to(include('launch_presentation_locale', 'tool_consumer_instance_guid'))
    end
  end
end
