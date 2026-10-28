# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Registration', type: :request) do
  let(:auth_headers) do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(ENV.fetch('ADMIN_KEY'), ENV.fetch('ADMIN_PASSWORD'))
    { 'HTTP_AUTHORIZATION' => credentials }
  end
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'registration-spec') }
  let(:key_pair) { create_key_pair(tool_id: 'spec-client-id') }

  def create_key_pair(tool_id: nil)
    private_key = OpenSSL::PKey::RSA.generate(2048)
    RsaKeyPair.create!(private_key: private_key.to_s, public_key: private_key.public_key.to_s, tool_id: tool_id)
  end

  def create_registration(rsa_key_pair_id, uuid: 'spec-client-id')
    RailsLti2Provider::Tool.create!(
      uuid: uuid,
      shared_secret: uuid,
      tool_settings: { client_id: uuid, rsa_key_pair_id: rsa_key_pair_id }.to_json,
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

  describe 'GET /registration/edit' do
    # submit tells an edit from a new registration by the uuid the form sends back
    it 'sends the current uuid along with the form' do
      create_registration(key_pair.id)
      get '/registration/edit', params: { uuid: 'spec-client-id' }, headers: auth_headers
      expect(response).to(have_http_status(:success))
      expect(response.body).to(match(/<input[^>]*type="hidden"[^>]*value="spec-client-id"[^>]*name="tool\[uuid\]"/))
    end
  end

  describe 'POST /registration/submit' do
    # The edit form sends the uuid it was opened with; the new form leaves it blank
    def submit(client_id:, rsa_key_pair_id:, uuid: nil, issuer: 'https://lms.example.com')
      post '/registration/submit', headers: auth_headers, params: {
        tool: {
          uuid: uuid,
          tenant_id: tenant.id,
          tool_settings: {
            issuer: issuer,
            client_id: client_id,
            key_set_url: 'https://lms.example.com/jwks',
            auth_token_url: 'https://lms.example.com/token',
            auth_login_url: 'https://lms.example.com/auth',
            rsa_key_pair_id: rsa_key_pair_id,
          },
          app_settings: { rooms: { institution_guid: 'spec' } },
        },
      }
    end

    def settings_of(registration)
      JSON.parse(registration.reload.tool_settings)
    end

    it 'renames the registration in place when the client ID changes' do
      registration = create_registration(key_pair.id)
      submit(uuid: 'spec-client-id', client_id: 'spec-renamed', rsa_key_pair_id: key_pair.id)
      expect(response.location).to(include('registration/list'))
      expect(RailsLti2Provider::Tool.count).to(eq(1))
      expect(registration.reload.uuid).to(eq('spec-renamed'))
      expect(registration.shared_secret).to(eq('spec-renamed'))
      expect(settings_of(registration)).to(include('client_id' => 'spec-renamed', 'rsa_key_pair_id' => key_pair.id))
      expect(key_pair.reload.tool_id).to(eq('spec-renamed'))
    end

    it 'updates the registration when the client ID is kept' do
      registration = create_registration(key_pair.id)
      submit(uuid: 'spec-client-id', client_id: 'spec-client-id', rsa_key_pair_id: key_pair.id, issuer: 'https://other.example.com')
      expect(RailsLti2Provider::Tool.count).to(eq(1))
      expect(settings_of(registration)).to(include('issuer' => 'https://other.example.com'))
    end

    it 'creates a registration from the new form' do
      new_pair = create_key_pair
      submit(client_id: 'spec-new', rsa_key_pair_id: new_pair.id)
      expect(response.location).to(include('registration/list'))
      expect(RailsLti2Provider::Tool.find_by(uuid: 'spec-new')).to(be_present)
      expect(new_pair.reload.tool_id).to(eq('spec-new'))
    end

    # Taking over the client ID of another registration would overwrite its settings.
    # The session cookie is secure, so these go over https to carry the flash message.
    it 'refuses to rename to a client ID that belongs to another registration' do
      https!
      registration = create_registration(key_pair.id)
      other_pair = create_key_pair(tool_id: 'spec-other')
      other = create_registration(other_pair.id, uuid: 'spec-other')
      other_settings = other.tool_settings

      submit(uuid: 'spec-client-id', client_id: 'spec-other', rsa_key_pair_id: key_pair.id)
      expect(response.location).to(include('registration/edit?uuid=spec-client-id'))
      expect(registration.reload.uuid).to(eq('spec-client-id'))
      expect(other.reload.tool_settings).to(eq(other_settings))
      expect(key_pair.reload.tool_id).to(eq('spec-client-id'))
      expect(other_pair.reload.tool_id).to(eq('spec-other'))

      # the message survives the redirect and shows up on the form
      get '/registration/edit', params: { uuid: 'spec-client-id' }, headers: auth_headers
      expect(response.body).to(include(I18n.t('registration.client_id_taken', client_id: 'spec-other')))
    end

    it 'refuses a new registration with a client ID already in use' do
      https!
      registration = create_registration(key_pair.id)
      settings = registration.tool_settings
      new_pair = create_key_pair

      submit(client_id: 'spec-client-id', rsa_key_pair_id: new_pair.id, issuer: 'https://other.example.com')
      expect(response.location).to(include('registration/new'))
      expect(RailsLti2Provider::Tool.count).to(eq(1))
      expect(registration.reload.tool_settings).to(eq(settings))
      expect(new_pair.reload.tool_id).to(be_nil)

      get '/registration/new', headers: auth_headers
      expect(response.body).to(include(I18n.t('registration.client_id_taken', client_id: 'spec-client-id')))
    end
  end

  describe 'GET /registration/delete' do
    def delete_registration(uuid)
      get '/registration/delete', params: { uuid: uuid }, headers: auth_headers
    end

    it 'deletes the key pair along with the only registration using it' do
      create_registration(key_pair.id)
      delete_registration('spec-client-id')
      expect(response.location).to(include('registration/list'))
      expect(RailsLti2Provider::Tool.find_by(uuid: 'spec-client-id')).to(be_nil)
      expect(RsaKeyPair.find_by(id: key_pair.id)).to(be_nil)
    end

    # Registrations duplicated by the old edit bug share one key pair
    it 'keeps the key pair while another registration still uses it' do
      create_registration(key_pair.id)
      create_registration(key_pair.id, uuid: 'spec-duplicate')
      key_pair.update!(tool_id: 'spec-client-id')

      delete_registration('spec-client-id')
      expect(RailsLti2Provider::Tool.find_by(uuid: 'spec-client-id')).to(be_nil)
      expect(key_pair.reload.tool_id).to(eq('spec-duplicate'))
    end

    it 'deletes a registration whose key pair is already gone' do
      create_registration(key_pair.id)
      key_pair.destroy!
      delete_registration('spec-client-id')
      expect(response.location).to(include('registration/list'))
      expect(RailsLti2Provider::Tool.find_by(uuid: 'spec-client-id')).to(be_nil)
    end
  end
end
