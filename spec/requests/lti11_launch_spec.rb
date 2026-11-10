# frozen_string_literal: true

require 'rails_helper'

# Runs a signed LTI 1.1 launch through the broker as the LMS and the app do
RSpec.describe('LTI 1.1 launch', type: :request) do
  let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'blti-spec', institution_guid: 'spec-institution') }
  let(:launch_url) { 'http://www.example.com/rooms/messages/blti' }
  let(:custom_params) { {} }

  before do
    Doorkeeper::Application.create!(name: 'rooms', redirect_uri: 'https://rooms.example.com/rooms/auth/bbbltibroker/callback')
    RailsLti2Provider::Tool.create!(uuid: 'blti-spec', shared_secret: 'blti-secret', lti_version: 'LTI-1p0', tenant: tenant, app_settings: {})
    stub_doorkeeper_token
  end

  def signed_launch_params
    params = {
      lti_version: 'LTI-1p0', user_id: 'user-1', roles: 'Instructor', context_id: 'course-1', context_title: 'Calculus I',
      resource_link_id: 'link-1', resource_link_title: 'Class room', tool_consumer_instance_guid: 'lms.example.com',
      lis_person_name_full: 'Jane Doe', lis_person_contact_email_primary: 'jane@example.com',
    }
    # an empty hash is signed but not posted, which breaks the signature
    params[:custom_params] = custom_params if custom_params.any?
    message = IMS::LTI::Models::Messages::BasicLTILaunchRequest.new(**params)
    message.launch_url = launch_url
    message.oauth_consumer_key = 'blti-spec'
    message.signed_post_params('blti-secret')
  end

  # LMS -> broker (blti) -> broker (app launch) -> app, which reads the launch from the sessions api
  def launch
    post launch_url, params: signed_launch_params
    expect(response).to(have_http_status(:success))
    form = Nokogiri::HTML(response.body).at('form')
    post form['action'], params: form.css('input[type=hidden]').to_h { |input| [input['name'], input['value']] }

    app_url = Nokogiri::HTML(response.body).at('form')['action']
    launch_nonce = Rack::Utils.parse_query(URI.parse(app_url).query)['launch_nonce']
    get "/api/v1/sessions/#{launch_nonce}"
    JSON.parse(response.body)['message']
  end

  it 'records the room in the support index with the handler Rooms computes' do
    message = launch
    expect(message['custom_params']).to(include('oauth_consumer_key' => 'blti-spec'))
    expect(LtiContext.sole).to(have_attributes(
                                 app: 'rooms', handler: Digest::SHA1.hexdigest('roomsblti-speccourse-1'),
                                 context_id: 'course-1', context_title: 'Calculus I', resource_link_id: 'link-1',
                                 tool_consumer_instance_guid: 'lms.example.com', groups_scoping: false
                               ))
  end

  # Rooms reads custom_params['custom_enable_groups_scoping'], but the LMS custom param reaches it
  # without the custom_ prefix, so Rooms ignores it and so must the index
  context 'when the LMS sends custom_enable_groups_scoping' do
    let(:custom_params) { { 'enable_groups_scoping' => 'true' } }

    it 'keeps the handler Rooms computes, without the resource link' do
      message = launch
      expect(message['custom_params']).to(include('enable_groups_scoping' => 'true'))
      expect(LtiContext.sole).to(have_attributes(handler: Digest::SHA1.hexdigest('roomsblti-speccourse-1'), groups_scoping: false))
    end
  end

  it 'still hands the launch to the app when the index fails' do
    allow(LtiContext).to(receive(:record_launch).and_raise(ActiveRecord::StatementInvalid, 'boom'))
    expect(launch).to(include('context_id' => 'course-1'))
  end
end
