# frozen_string_literal: true

class RemoveOldAppLaunchJob < ApplicationJob
  def perform
    Resque.logger.info('Removing old AppLaunches')
    date_limit = Rails.configuration.app_launch_days_to_delete.days.ago.utc
    query_started = Time.now.utc
    deleted_launches = AppLaunch.where('expiration_time < ?', date_limit).delete_all
    query_duration = Time.now.utc - query_started
    Resque.logger.info("Removed the AppLaunches from before #{date_limit}, " \
                      "#{deleted_launches} AppLaunches deleted, " \
                      "in: #{query_duration.round(3)} seconds")
  end
end
