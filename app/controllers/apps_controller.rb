# frozen_string_literal: true

class AppsController < ApplicationController
  # verified oauth, etc
  # launch into lti application
  def launch
    # Make launch request to LTI-APP
    redirector = "#{lti_app_url(params[:app])}?#{{ launch_nonce: app_launch.nonce }.to_query}"
    redirect_to(redirector)
  end

  private

  def app_launch
    tool = RailsLti2Provider::Tool.where(uuid: params[:oauth_consumer_key]).last
    lti_launch = RailsLti2Provider::LtiLaunch.find_by(nonce: params[:oauth_nonce])

    # add the oauth key to the data of this launch
    message = lti_launch.message
    message.custom_params['oauth_consumer_key'] = params[:oauth_consumer_key]

    AppLaunch.find_or_create_by(nonce: lti_launch.nonce) do |launch|
      launch.update(tool_id: tool.id, message: message.to_json)
    end
  end
end
