# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Application index', type: :request) do
  describe 'GET /' do
    # developer_mode_enabled and default_tool are read from the environment once, at boot,
    # so a test cannot change them by setting ENV. Stub the resolved config instead.
    def stub_config(developer_mode:, default_tool: 'rooms')
      allow(Rails.configuration).to(receive(:developer_mode_enabled).and_return(developer_mode))
      allow(Rails.configuration).to(receive(:default_tool).and_return(default_tool))
    end

    it 'renders the page with the xml config link when developer mode is disabled' do
      stub_config(developer_mode: false)
      get '/'
      expect(response).to(have_http_status(:success))
      expect(response.body).to(include('rooms/xml_config'))
    end

    it 'renders the page with the xml builder link when developer mode is enabled' do
      stub_config(developer_mode: true)
      get '/'
      expect(response).to(have_http_status(:success))
      expect(response.body).to(include('rooms/xml_builder'))
    end

    # ToolProfileController answers 404 for the default app outside developer mode
    it 'leaves out the xml config link when the default app is hidden' do
      stub_config(developer_mode: false, default_tool: 'default')
      get '/'
      expect(response).to(have_http_status(:success))
      expect(response.body).not_to(include('xml_config'))
    end
  end
end
