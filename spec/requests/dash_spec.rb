# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Dash RsaKeyPair', type: :request) do
  before { create_key_pair(tool_id: 'dash-spec') }

  # The HTML sections hide the field, but the json, xml and csv outputs bypass them
  it 'leaves the private key out of the json list' do
    get '/dash/rsa_key_pair.json', headers: auth_headers
    expect(response).to(have_http_status(:success))
    expect(response.body).to(include('PUBLIC KEY'))
    expect(response.body).not_to(include('PRIVATE KEY'))
  end

  %w[json xml csv].each do |format|
    it "leaves the private key out of the #{format} export, even when asked for it" do
      post '/dash/rsa_key_pair/export',
           params: { format => 'true', schema: { only: %w[id public_key private_key], methods: %w[private_key] }, csv_options: { generator: { col_sep: ',' } } },
           headers: auth_headers
      expect(response).to(have_http_status(:success))
      expect(response.body).to(include('PUBLIC KEY'))
      expect(response.body).not_to(include('PRIVATE KEY'))
    end
  end
end
