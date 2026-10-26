# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Registration', type: :request) do
  let(:auth_headers) do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(ENV.fetch('ADMIN_KEY'), ENV.fetch('ADMIN_PASSWORD'))
    { 'HTTP_AUTHORIZATION' => credentials }
  end
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'registration-spec') }
  let(:key_pair) do
    private_key = OpenSSL::PKey::RSA.generate(2048)
    RsaKeyPair.create!(private_key: private_key.to_s, public_key: private_key.public_key.to_s, tool_id: 'spec-client-id')
  end

  def create_registration(rsa_key_pair_id)
    RailsLti2Provider::Tool.create!(
      uuid: 'spec-client-id',
      shared_secret: 'spec-client-id',
      tool_settings: { client_id: 'spec-client-id', rsa_key_pair_id: rsa_key_pair_id }.to_json,
      app_settings: {},
      lti_version: '1.3.0',
      tenant: tenant
    )
  end

  describe 'GET /registration/new' do
    before { tenant }

    # Bootstrap 5 only reacts to the data-bs-* attributes; data-toggle/data-target are Bootstrap 4
    it 'renders the collapse toggles with the Bootstrap 5 attributes' do
      get '/registration/new', headers: auth_headers
      expect(response).to(have_http_status(:success))
      expect(response.body).to(include('data-bs-toggle="collapse"'))
      expect(response.body).to(include('data-bs-target="#collapseStarterInfo"'))
      expect(response.body).not_to(include('data-toggle='))
      expect(response.body).not_to(include('data-target='))
    end
  end

  describe 'GET /registration/show' do
    it 'shows the public key of the registration' do
      create_registration(key_pair.id)
      get '/registration/show', params: { uuid: 'spec-client-id' }, headers: auth_headers
      expect(response).to(have_http_status(:success))
      expect(response.body).to(include(ERB::Util.html_escape(key_pair.public_key).strip))
    end

    it 'renders without the public key when the key pair was deleted' do
      create_registration(key_pair.id)
      key_pair.destroy!
      get '/registration/show', params: { uuid: 'spec-client-id' }, headers: auth_headers
      expect(response).to(have_http_status(:success))
      expect(response.body).not_to(include('BEGIN PUBLIC KEY'))
    end
  end
end
