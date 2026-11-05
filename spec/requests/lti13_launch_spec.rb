# frozen_string_literal: true

require 'rails_helper'

# Runs the 1.3 launch through the broker as the LMS and the app do, so a change in how the launch
# message is stored shows up here
RSpec.describe('LTI 1.3 launch', type: :request) do
  let(:platform_key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:platform_jwk) { JWT::JWK.new(platform_key) }
  let(:key_set_url) { 'https://lms.example.com/mod/lti/certs.php' }
  let(:nonce) { 'nonce-launch-spec' }
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'launch-spec', institution_guid: 'spec-institution') }
  let(:roles) { [LtiHelpers::LEARNER] }
  let(:claims) do
    lti13_claims(roles: roles).merge(
      'iss' => 'https://lms.example.com',
      'aud' => 'launch-spec',
      'nonce' => nonce,
      'exp' => 1.hour.from_now.to_i,
      'iat' => Time.now.to_i
    )
  end

  before do
    Doorkeeper::Application.create!(name: 'rooms', redirect_uri: 'https://rooms.example.com/rooms/auth/bbbltibroker/callback')
    RailsLti2Provider::Tool.create!(
      uuid: 'launch-spec', shared_secret: 'launch-spec', lti_version: '1.3.0', tenant: tenant, app_settings: {},
      tool_settings: { client_id: 'launch-spec', issuer: 'https://lms.example.com', key_set_url: key_set_url }.to_json
    )

    # The login step stores the nonce in the cache, which is a null store in the test environment
    allow(Rails).to(receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new))
    Rails.cache.write("lti1p3_#{nonce}", nonce: nonce)

    stub_request(:get, key_set_url).to_return(body: { keys: [platform_jwk.export] }.to_json)
    stub_doorkeeper_token
  end

  def post_id_token(claims, key: platform_key)
    id_token = JWT.encode(claims, key, 'RS256', { kid: platform_jwk.kid })
    post '/rooms/messages/oblti', params: { state: 'state-launch-spec', id_token: id_token }
  end

  # redirect_post answers with a form that the browser submits on load
  def submit_redirect_form
    form = Nokogiri::HTML(response.body).at('form')
    fields = form.css('input[type=hidden]').to_h { |input| [input['name'], input['value']] }
    post form['action'], params: fields
    form['action']
  end

  # LMS -> broker (oblti) -> broker (app launch) -> app, which reads the launch from the sessions api
  def launch
    post_id_token(claims)
    expect(response).to(have_http_status(:success))
    expect(submit_redirect_form).to(include('/rooms/launch', "oauth_nonce=#{nonce}"))

    expect(response).to(have_http_status(:success))
    app_url = Nokogiri::HTML(response.body).at('form')['action']
    expect(app_url).to(start_with('https://rooms.example.com/rooms/launch?'))
    launch_nonce = Rack::Utils.parse_query(URI.parse(app_url).query)['launch_nonce']
    expect(launch_nonce).to(eq(nonce))

    get "/api/v1/sessions/#{launch_nonce}"
    expect(response).to(have_http_status(:success))
    JSON.parse(response.body)
  end

  { 'a learner' => [LtiHelpers::LEARNER], 'an instructor' => [LtiHelpers::INSTRUCTOR] }.each do |who, launch_roles|
    context "when #{who} opens the activity" do
      let(:roles) { launch_roles }

      it 'hands the launch to the app with the claims mapped to the LTI 1.1 parameters' do
        body = launch
        expect(body).to(include('valid' => true, 'tenant' => 'launch-spec'))
        expect(body['message']).to(include(
                                     'user_id' => 'user-1',
                                     'lis_person_name_full' => 'Jane Doe',
                                     'roles' => launch_roles.join(','),
                                     'context_id' => 'course-1',
                                     'context_title' => 'Calculus I',
                                     'context_label' => 'CALC1',
                                     'resource_link_id' => 'link-1'
                                   ))
        # The apps read the tenant and app configs from custom_params, without the custom_ prefix
        expect(body['message']['custom_params']).to(include('oauth_consumer_key' => 'launch-spec', 'institution_guid' => 'spec-institution'))
      end
    end
  end

  # consider_all_requests_local is on in the test environment, so the errors reach the spec
  describe 'a launch the broker refuses' do
    it 'rejects an id_token signed with another key' do
      expect { post_id_token(claims, key: OpenSSL::PKey::RSA.generate(2048)) }.to(raise_error(JWT::VerificationError))
      expect(RailsLti2Provider::LtiLaunch.count).to(eq(0))
    end

    it 'rejects a client ID without a registration' do
      expect { post_id_token(claims.merge('aud' => 'not-registered')) }.to(raise_error(ExceptionHandler::CustomError) { |error| expect(error.error).to(eq(:not_registered)) })
      expect(RailsLti2Provider::LtiLaunch.count).to(eq(0))
    end

    # A nonce missing from the cache still fails before validate_nonce raises :invalid_nonce
    it 'rejects a nonce the login step did not issue' do
      expect { post_id_token(claims.merge('nonce' => 'nonce-not-issued')) }.to(raise_error(StandardError))
      expect(RailsLti2Provider::LtiLaunch.count).to(eq(0))
    end
  end
end
