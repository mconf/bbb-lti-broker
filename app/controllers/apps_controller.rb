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

class AppsController < ApplicationController
  before_action :print_parameters if Rails.configuration.developer_mode_enabled

  # verified oauth, etc
  # launch into lti application
  def launch
    # Make launch request to LTI-APP
    tool = RailsLti2Provider::Tool.where(uuid: params[:oauth_consumer_key]).last
    lti_launch = RailsLti2Provider::LtiLaunch.find_by(nonce: params[:oauth_nonce])

    Rails.logger.info "Creating a launch for tool=#{tool.uuid} and " \
                      "oauth_nonce=#{params[:oauth_nonce]}"

    # add the oauth key to the data of this launch
    message = lti_launch.message
    message.custom_params['oauth_consumer_key'] = params[:oauth_consumer_key]

    AppLaunch.find_or_create_by(nonce: lti_launch.nonce) do |launch|
      launch.update(tool_id: tool.id, message: message.to_json)
    end

    redirector = "#{lti_app_url(params[:app])}?#{{ launch_nonce: lti_launch.nonce }.to_query}"
    redirect_post(redirector, options: { authenticity_token: :auto })
  end
end
