# frozen_string_literal: true

class RemoveOldLtiLaunchJob < ApplicationJob
  def perform
    Resque.logger.info('Removing old LtiLaunch')
    query_started = Time.now.utc
    date_limit = Rails.configuration.lti_launch_days_to_delete.days.ago.utc
    deleted_lti_launches = RailsLti2Provider::LtiLaunch.where('created_at > ?', date_limit).delete_all
    query_duration = Time.now.utc - query_started
    Resque.logger.info("Removed the LtiLaunch from before #{date_limit}, " \
                      "#{deleted_lti_launches} LtiLaunch deleted, " \
                      "in: #{query_duration.round(3)} seconds")
  end
end
