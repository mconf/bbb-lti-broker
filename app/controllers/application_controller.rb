# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'ims/lti'
require 'securerandom'
require 'faraday'
require 'oauthenticator'
require 'oauth'
require 'addressable/uri'
require 'oauth/request_proxy/action_controller_request'

class ApplicationController < ActionController::Base
  include AppsValidator

  unless Rails.application.config.consider_all_requests_local
    rescue_from StandardError, with: :on_500
    rescue_from ActionController::RoutingError, with: :on_404
    rescue_from ActiveRecord::RecordNotFound, with: :on_404
    rescue_from ActionController::UnknownFormat, with: :on_406
  end

  protect_from_forgery with: :exception

  @build_number = Rails.configuration.build_number

  def on_404
    render_error(404)
  end

  # 406 Not Acceptable
  def on_406
    render_error(406)
  end

  def on_500
    render_error(500)
  end

  private

  def render_error(status)
    @error = {
      key: t("error.generic.#{status}.code"),
      message: t("error.generic.#{status}.message"),
      suggestion: t("error.generic.#{status}.suggestion"),
      code: status,
      status: status
    }

    respond_to do |format|
      format.html { render 'shared/error', status: status }
      format.json { render json: { error: @error[:message] }, status: status }
      format.all  { render 'shared/error', status: status, content_type: 'text/html' }
    end
  end
end
