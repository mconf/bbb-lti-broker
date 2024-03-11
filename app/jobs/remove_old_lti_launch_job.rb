# frozen_string_literal: true

class RemoveOldLtiLaunchJob < ApplicationJob
  def perform
    date_limit = Rails.configuration.lti_launch_days_to_delete.days.ago.utc
    limit_launch_to_delete = Rails.configuration.limit_launch_to_delete

    lti_launches = get_expired_launches(date_limit).count
    Resque.logger.info "There are #{lti_launches} expired LtiLaunches"

    while lti_launches > 0
      Resque.logger.info "Removing old LtiLaunches:"
      begin
        query_started = Time.now.utc
        deleted_lti_launches = get_expired_launches(date_limit).limit(limit_launch_to_delete)
                                                               .delete_all

        query_duration = Time.now.utc - query_started
        Resque.logger.info "Removed LtiLaunches from before #{date_limit}, " \
                           "#{deleted_lti_launches} entries deleted " \
                           "in: #{query_duration.round(3)} seconds"
        
        lti_launches = get_expired_launches(date_limit).count
      rescue StandardError => e
        Resque.logger.error "Error removing old LtiLaunch: #{e.message}", \
                            "These #{deleted_lti_launches} have not been deleted."
      end
    end
  end

  def get_expired_launches(date)
    lti_launches = RailsLti2Provider::LtiLaunch.where('created_at < ?', date)
  end
end
