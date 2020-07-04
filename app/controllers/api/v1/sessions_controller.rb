# frozen_string_literal: true

class Api::V1::SessionsController < Api::V1::BaseController
  before_action :doorkeeper_authorize!

  def validate_launch
    app_launch = AppLaunch.find_by(nonce: params[:token])
    if app_launch.present?
      msg = { token: params[:token], valid: true, message: JSON.parse(app_launch.message) }
      render(json: msg.to_json)
    else
      render(json: { token: params[:token], valid: false }.to_json)
    end
  end

  def invalidate_launch
    app_launch = AppLaunch.find_by(nonce: params[:token])
    if app_launch.present?
      app_launch.invalidate!
      changed = true
    else
      changed = false
    end
    render(json: { token: params[:token], changed: changed }.to_json)
  end
end
