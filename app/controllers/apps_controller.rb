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

    Rails.logger.info "Creating a launch for tool=#{tool.uuid} and " \
                      "oauth_nonce=#{params[:oauth_nonce]}"

    # add the oauth key to the data of this launch
    message = lti_launch.message
    message.custom_params['oauth_consumer_key'] = params[:oauth_consumer_key]

    # FIX ME
    # Move to a worker or cache the result
    date_limit = Rails.configuration.launch_days_to_delete.days.ago.utc
    query_started = Time.now.utc
    deleted_launches = AppLaunch.where('expiration_time < ?', date_limit).delete_all
    query_duration = Time.now.utc - query_started
    Rails.logger.info "Removing the old AppLaunches from before #{date_limit}, " \
                      "#{deleted_launches} AppLaunches deleted, " \
                      "in: #{query_duration.round(3)} seconds"

    AppLaunch.find_or_create_by(nonce: lti_launch.nonce) do |launch|
      launch.update(tool_id: tool.id, message: message.to_json)
    end
  end
end
