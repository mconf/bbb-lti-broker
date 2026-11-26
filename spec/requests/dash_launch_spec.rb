# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Dash launch', type: :request) do
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'dash-request', institution_guid: 'spec-institution') }
  let(:tool) { RailsLti2Provider::Tool.create!(uuid: 'dash-request', shared_secret: 'secret', lti_version: 'LTI-1p0', tenant: tenant, app_settings: {}) }
  let(:handler) { Digest::SHA1.hexdigest('roomsdash-requestcourse-1') }
  let(:context) do
    LtiContext.create!(tool: tool, app: 'rooms', rooms_handler: handler, oauth_consumer_key: 'dash-request', context_id: 'course-1',
                       context_title: 'Calculus I', last_launch_at: Time.current)
  end
  let(:context_path) { "/dash/lti_context/#{context.id}/dash_launch_action" }
  let(:tool_path) { "/dash/rails_lti2_provider~tool/#{tool.id}/dash_launch_action" }
  let(:form) { { name: 'Jane Doe', lti_role: 'Learner' } }

  let(:enabled) { 'true' }

  around do |example|
    ENV['DASH_LAUNCH_ENABLED'] = enabled
    example.run
  ensure
    ENV.delete('DASH_LAUNCH_ENABLED')
  end

  before { Doorkeeper::Application.create!(name: 'rooms', redirect_uri: 'https://rooms.example.com/rooms/auth/bbbltibroker/callback') }

  it 'shows the form for a room in the history' do
    get context_path, headers: auth_headers
    expect(response).to(have_http_status(:success))
    expect(response.body).to(include(handler, 'Your name'))
  end

  it 'shows the form for a new room from a tool' do
    get tool_path, headers: auth_headers
    expect(response).to(have_http_status(:success))
  end

  it 'tells the form which room a handler is' do
    context
    get tool_path, params: { lookup: handler }, headers: auth_headers
    expect(response.parsed_body).to(include('context_id' => 'course-1', 'context_title' => 'Calculus I'))
    get tool_path, params: { lookup: 'unknown' }, headers: auth_headers
    expect(response.parsed_body).to(eq({}))

    other_tool = RailsLti2Provider::Tool.create!(uuid: 'dash-other', shared_secret: 'secret', lti_version: 'LTI-1p0', tenant: tenant, app_settings: {})
    get "/dash/rails_lti2_provider~tool/#{other_tool.id}/dash_launch_action", params: { lookup: handler }, headers: auth_headers
    expect(response.parsed_body).to(eq('other_tool' => 'dash-request'))
  end

  it 'refuses a launch without a name' do
    post context_path, params: { dash_launch: form.merge(name: '') }, headers: auth_headers
    expect(response).to(have_http_status(:unprocessable_entity))
    expect(RailsLti2Provider::LtiLaunch.count).to(eq(0))
    expect(DashLaunchLog.count).to(eq(0))
  end

  it 'launches into the room of the history, as the app will read it, ignoring a course sent with it' do
    stub_doorkeeper_token
    context

    post context_path, params: { dash_launch: form.merge(context_id: 'other-course') }, headers: auth_headers
    expect(response).to(redirect_to(%r{/rooms/launch\?oauth_nonce=}))

    get response.location
    app_url = Nokogiri::HTML(response.body).at('form')['action']
    expect(app_url).to(start_with('https://rooms.example.com/rooms/launch?'))
    launch_nonce = Rack::Utils.parse_query(URI.parse(app_url).query)['launch_nonce']

    get "/api/v1/sessions/#{launch_nonce}"
    message = JSON.parse(response.body)['message']
    expect(message).to(include('user_id' => 'dash-jane-doe', 'roles' => 'Learner', 'context_id' => 'course-1'))
    expect(message['custom_params']).to(include('custom_dash_launch' => 'jane-doe', 'oauth_consumer_key' => 'dash-request'))
    expect(LtiContext.rooms_handler(message)).to(eq(handler))

    launch = RailsLti2Provider::LtiLaunch.find_by(nonce: launch_nonce)
    expect(User.find(launch.user_id).uid).to(eq(message['user_id']))
    expect(DashLaunchLog.sole).to(have_attributes(operator: 'jane-doe', app: 'rooms', rooms_handler: handler, role: 'Learner'))
    expect(LtiContext.sole).to(eq(context))
  end

  it 'launches from a tool into the room of a typed handler' do
    context
    post tool_path, params: { dash_launch: form.merge(app: 'rooms', handler: handler) }, headers: auth_headers
    expect(response).to(redirect_to(%r{/rooms/launch\?oauth_nonce=}))
    expect(DashLaunchLog.sole).to(have_attributes(rooms_handler: handler))
  end

  it 'keeps the access log read-only in the dash' do
    access = DashLaunchLog.create!(operator: 'jane-doe')
    get "/dash/dash_launch_log/#{access.id}/edit", headers: auth_headers
    expect(response).not_to(have_http_status(:success))
    get "/dash/dash_launch_log/#{access.id}/delete", headers: auth_headers
    expect(response).not_to(have_http_status(:success))
  end

  context 'when the broker does not offer dash launches' do
    let(:enabled) { 'false' }

    it 'has no dash launch action' do
      get context_path, headers: auth_headers
      expect(response).not_to(have_http_status(:success))
      post context_path, params: { dash_launch: form }, headers: auth_headers
      expect(RailsLti2Provider::LtiLaunch.count).to(eq(0))
    end
  end
end
