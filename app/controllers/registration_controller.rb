# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'json'
require 'pathname'

class RegistrationController < ApplicationController
  skip_before_action :verify_authenticity_token
  include PlatformValidator
  include AppsValidator
  include TemporaryStore

  http_basic_authenticate_with name: ENV['ADMIN_KEY'], password: ENV['ADMIN_PASSWORD']

  before_action :print_parameters if Rails.configuration.developer_mode_enabled

  def list
    @tools_1p3 = RailsLti2Provider::Tool.where(lti_version: '1.3.0').sort
    @tools_1p0 = RailsLti2Provider::Tool.where(lti_version: 'LTI-1p0').sort
    @tenants = RailsLti2Provider::Tenant.all.sort
  end

  def show
    redirect_to(registration_list_path) unless params.key?('uuid')
    redirect_to(registration_list_path) unless lti_registration_exists?(params[:uuid])

    @registration = lti_registration_params(params[:uuid])
    @tool = lti_registration(params[:uuid])
  end

  def new
    @app = Rails.configuration.default_tool
    @apps = lti_apps
    @tenants = RailsLti2Provider::Tenant.all.sort.pluck(:uid, :id)
    @tool = RailsLti2Provider::Tool.new(tenant_id: @tenants[0][1])
    set_rsa_keys
    set_starter_info
  end

  def edit
    redirect_to(registration_list_path) unless params.key?('uuid')
    redirect_to(registration_list_path) unless lti_registration_exists?(params[:uuid])

    @registration = lti_registration_params(params[:uuid])
    @tool = lti_registration(params[:uuid])
    @tenants = RailsLti2Provider::Tenant.all.sort.pluck(:uid, :id)
  end

  def submit
    settings_params = tool_params[:tool_settings]
    return if settings_params[:client_id] == ''

    if settings_params.key?('rsa_key_pair_id')
      key_pair = RsaKeyPair.find(settings_params[:rsa_key_pair_id])
      redirect_to(new_registration_path) and return if key_pair.nil?

      key_pair.update(tool_id: settings_params[:client_id])
    end

    registration = lti_registration(settings_params[:client_id]) if tool_params[:tool_settings].key?('client_id')
    unless registration.nil?
      settings_params[:rsa_key_pair_id] = lti_registration_params(settings_params[:client_id])['rsa_key_pair_id']
      registration.update(
        tool_settings: settings_params.to_json,
        shared_secret: settings_params[:client_id],
        app_settings: tool_params[:app_settings],
        tenant: RailsLti2Provider::Tenant.find_by(id: tool_params[:tenant_id])
      )
      registration.save
      redirect_to(registration_list_path) and return
    end

    RailsLti2Provider::Tool.create!(
      uuid: settings_params[:client_id],
      shared_secret: settings_params[:client_id],
      tool_settings: settings_params.to_json,
      app_settings: tool_params[:app_settings],
      lti_version: '1.3.0',
      tenant: RailsLti2Provider::Tenant.find_by(id: tool_params[:tenant_id])
    )

    redirect_to(registration_list_path)
  end

  def delete
    if lti_registration_exists?(params[:uuid])
      reg = lti_registration(params[:uuid])
      if key_pair_id = lti_registration_params(params[:uuid])['rsa_key_pair_id']
        RsaKeyPair.find(key_pair_id).destroy
      end
      reg.delete
    end
    redirect_to(registration_list_path)
  end

  private

  def set_rsa_keys
    private_key = OpenSSL::PKey::RSA.generate(4096)
    @jwk = JWT::JWK.new(private_key).export
    @jwk['alg'] = 'RS256' unless @jwk.key?('alg')
    @jwk['use'] = 'sig' unless @jwk.key?('use')
    @jwk = @jwk.to_json

    @public_key = private_key.public_key

    # delete old temp key_pairs that didn't get associated with a tool
    RsaKeyPair.where(tool_id: nil).where('created_at < ?', 6.hours.ago).delete_all
    @rsa_key_pair = RsaKeyPair.create(private_key: private_key.to_s, public_key: @public_key.to_s)

    # keep key_pair_id in cache for json configuration
    @temp_key_token = SecureRandom.hex
    Rails.cache.write(@temp_key_token, rsa_key_pair_id: @rsa_key_pair.id, timestamp: Time.now.to_i)
  end

  def set_starter_info
    basic_launch_url = openid_launch_url(app: @app)
    deep_link_url = deep_link_request_launch_url(app: @app)
    @redirect_uri = "#{basic_launch_url}\n#{deep_link_url}"
  end

  def tool_params
    params.require(:tool).permit(:uuid, :shared_secret, :tenant_id,
    tool_settings: {}, app_settings: {}).tap do |whitelisted|
      # Filter app_settings params
      whitelisted[:app_settings].each do |app_name, settings|
        # Reject blank values
        settings.compact_blank!
        # Reject 'false' values from checkboxes
        settings.delete_if { |key, val| key.include?('_enabled') && val == '0' }
      end
    end
  end
end
