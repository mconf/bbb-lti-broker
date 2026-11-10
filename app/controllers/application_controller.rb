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

require 'uri'
require 'net/http'
require 'ims/lti'
require 'securerandom'
require 'faraday'
require 'oauthenticator'
require 'oauth'
require 'yaml'
require 'addressable/uri'
require 'oauth/request_proxy/action_controller_request'

class ApplicationController < ActionController::Base
  include AppsValidator

  unless Rails.application.config.consider_all_requests_local
    rescue_from StandardError, with: :on500
    rescue_from ActionController::RoutingError, with: :on404
    rescue_from ActiveRecord::RecordNotFound, with: :on404
    rescue_from ActionController::UnknownFormat, with: :on406
    rescue_from ActionController::InvalidAuthenticityToken, with: :on406
  end

  protect_from_forgery with: :exception

  helper_method :default_app_hidden?

  @build_number = Rails.configuration.build_number

  def on404
    render_error(404)
  end

  # 406 Not Acceptable
  def on406
    render_error(406)
  end

  # rescue_from passes the exception when the handler accepts it
  def on500(exception = nil)
    if exception
      logger.error("#{exception.class}: #{exception.message}")
      logger.error(Array(exception.backtrace).first(15).join("\n"))
    end
    render_error(500)
  end

  private

  # The default app is only served in developer mode
  def default_app_hidden?(app = Rails.configuration.default_tool)
    app == 'default' && !Rails.configuration.developer_mode_enabled
  end

  def render_error(status)
    @error = {
      key: t("error.generic.#{status}.code"),
      message: t("error.generic.#{status}.message"),
      suggestion: t("error.generic.#{status}.suggestion"),
      code: status,
      status: status,
    }

    respond_to do |format|
      format.html { render('errors/index', status: status, layout: false) }
      format.json { render(json: { error: @error[:message] }, status: status) }
      format.all  { render('errors/index', status: status, content_type: 'text/html') }
    end
  end

  def print_parameters
    logger.debug(params.to_unsafe_h.sort.to_h.to_yaml)
  end
end
