# frozen_string_literal: true

class Api::V1::SessionsController < Api::V1::BaseController
  before_action :doorkeeper_authorize!

  def validate_launch
    app_launch = AppLaunch.find_by(nonce: params[:token])
    render(json: { token: params[:token], valid: false }.to_json) unless app_launch
    render(json: { token: params[:token], valid: true, message: JSON.parse(app_launch.message) }.to_json)
  end

  def invalidate_launch
    app_launch = AppLaunch.find_by(nonce: params[:token])
    render(json: { token: params[:token], changed: false }.to_json) unless app_launch

    app_launch.invalidate!
    render(json: { token: params[:token], changed: true }.to_json)
  end
end
