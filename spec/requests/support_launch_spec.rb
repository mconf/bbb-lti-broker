# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Dash support launch', type: :request) do
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'support-dash', institution_guid: 'spec-institution') }
  let(:tool) { RailsLti2Provider::Tool.create!(uuid: 'support-dash', shared_secret: 'secret', lti_version: 'LTI-1p0', tenant: tenant, app_settings: {}) }
  let(:handler) { Digest::SHA1.hexdigest('roomssupport-dashcourse-1') }
  let(:context) do
    LtiContext.create!(tool: tool, app: 'rooms', handler: handler, oauth_consumer_key: 'support-dash', context_id: 'course-1',
                       context_title: 'Calculus I', last_launch_at: Time.current)
  end
  let(:context_path) { "/dash/lti_context/#{context.id}/support_launch_action" }
  let(:form) { { tool_id: tool.id, operator: 'jane.doe', display_name: 'Suporte', lti_role: 'Learner', context_id: 'course-1', context_title: 'Calculus I' } }

  let(:enabled) { 'true' }

  around do |example|
    ENV['SUPPORT_LAUNCH_ENABLED'] = enabled
    example.run
  ensure
    ENV.delete('SUPPORT_LAUNCH_ENABLED')
  end

  before { Doorkeeper::Application.create!(name: 'rooms', redirect_uri: 'https://rooms.example.com/rooms/auth/bbbltibroker/callback') }

  it 'shows the form for a room in the index' do
    get context_path, headers: auth_headers
    expect(response).to(have_http_status(:success))
    expect(response.body).to(include(handler, 'Who is accessing'))
  end

  it 'shows the form for a new room from a tool' do
    get "/dash/rails_lti2_provider~tool/#{tool.id}/support_launch_action", headers: auth_headers
    expect(response).to(have_http_status(:success))
  end

  it 'refuses a launch without the operator' do
    post context_path, params: { support_launch: form.merge(operator: '') }, headers: auth_headers
    expect(response).to(have_http_status(:unprocessable_entity))
    expect(RailsLti2Provider::LtiLaunch.count).to(eq(0))
    expect(SupportAccess.count).to(eq(0))
  end

  it 'launches into the room of the index, as the app will read it, without touching the index' do
    stub_doorkeeper_token
    context

    post context_path, params: { support_launch: form }, headers: auth_headers
    expect(response).to(redirect_to(%r{/rooms/launch\?oauth_nonce=}))

    get response.location
    app_url = Nokogiri::HTML(response.body).at('form')['action']
    expect(app_url).to(start_with('https://rooms.example.com/rooms/launch?'))
    launch_nonce = Rack::Utils.parse_query(URI.parse(app_url).query)['launch_nonce']

    get "/api/v1/sessions/#{launch_nonce}"
    message = JSON.parse(response.body)['message']
    expect(message).to(include('user_id' => 'elos-support-jane.doe', 'roles' => 'Learner', 'context_id' => 'course-1'))
    expect(message['custom_params']).to(include('custom_elos_support' => 'jane.doe', 'oauth_consumer_key' => 'support-dash'))
    expect(LtiContext.rooms_handler(message)).to(eq(handler))

    launch = RailsLti2Provider::LtiLaunch.find_by(nonce: launch_nonce)
    expect(User.find(launch.user_id).uid).to(eq(message['user_id']))
    expect(SupportAccess.sole).to(have_attributes(operator: 'jane.doe', handler: handler, role: 'Learner'))
    expect(LtiContext.sole).to(eq(context))
  end

  it 'keeps the access log read-only in the dash' do
    access = SupportAccess.create!(operator: 'jane.doe', kind: 'launch')
    get "/dash/support_access/#{access.id}/edit", headers: auth_headers
    expect(response).not_to(have_http_status(:success))
    get "/dash/support_access/#{access.id}/delete", headers: auth_headers
    expect(response).not_to(have_http_status(:success))
  end

  context 'when the broker does not offer support launches' do
    let(:enabled) { 'false' }

    it 'has no support launch action' do
      get context_path, headers: auth_headers
      expect(response).not_to(have_http_status(:success))
      post context_path, params: { support_launch: form }, headers: auth_headers
      expect(RailsLti2Provider::LtiLaunch.count).to(eq(0))
    end
  end
end
