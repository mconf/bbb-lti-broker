class RemoveOldAppLaunchJob < ApplicationJob
  def perform()
    date_limit = Rails.configuration.app_launch_days_to_delete.days.ago.utc
    limit_launch_to_delete = Rails.configuration.limit_launch_to_delete

    app_launches  = get_expired_launches(date_limit).count
    Resque.logger.info "There are #{app_launches} expired AppLaunches"

    while app_launches > 0
      Resque.logger.info "Removing old AppLaunches:"
      begin
        query_started = Time.now.utc
        deleted_launches = get_expired_launches(date_limit).limit(limit_launch_to_delete).delete_all

        query_duration = Time.now.utc - query_started
        Resque.logger.info "Removed the AppLaunches from before #{date_limit}, " \
                           "#{deleted_launches} AppLaunches deleted, " \
                           "in: #{query_duration.round(3)} seconds"

        app_launches = get_expired_launches(date_limit).count
      rescue StandardError => e
        Resque.logger.error "Error removing old LtiLaunch: #{e.message}", \
                            "These #{deleted_launches} has not been deleted."
      end
    end
  end

  def get_expired_launches(date)
    app_launches = AppLaunch.where('expiration_time < ?', date)
  end
end
