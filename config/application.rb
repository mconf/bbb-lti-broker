# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'
require_relative '../lib/simple_json_formatter'
require_relative '../lib/mconf/env'

# Load the app's custom environment variables here, so that they are loaded before environments/*.rb

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BbbLtiBroker
  class Application < Rails::Application
    VERSION = "0.4.0"

    config.eager_load_paths << Rails.root.join('lib')

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.url_host = ENV['URL_HOST']

    config.build_number = ENV['BUILD_NUMBER'] || VERSION

    config.log_level = ENV['LOG_LEVEL'] || :debug

    config.launch_nonce_duration = (ENV['LAUNCH_NONCE_DURATION'] || 300).to_i.seconds

    # Configures how many days AppLaunches will be kept on the db.
    # AppLaunches that are more than {app_launch_days_to_delete} days old will be deleted
    # every time app_launch is called.
    config.app_launch_days_to_delete = (ENV['APP_LAUNCH_DAYS_TO_DELETE'] || 15).to_i
    config.lti_launch_days_to_delete = (ENV['LTI_LAUNCH_DAYS_TO_DELETE'] || 1).to_i
    config.limit_launch_to_delete = (ENV['LIMIT_LAUNCH_TO_DELETE'] || 1000).to_i

    config.app_name = ENV["APP_NAME"] || 'BbbLtiBroker'

    # FIX ME, move this elsewhere
    config.coc_client_id = ENV['COC_CLIENT_ID']
    config.coc_client_secret = ENV['COC_CLIENT_SECRET']
    config.coc_consumer_key = ENV['COC_CONSUMER_KEY']
    config.coc_consumer_secret = ENV['COC_CONSUMER_SECRET']
    config.coc_portal_host = ENV['COC_PORTAL_HOST']
    config.coc_package_id = ENV['COC_PACKAGE_ID']
    config.coc_passaporte_host = ENV['COC_PASSAPORTE_URI']

    # use a json formatter to match lograge's logs
    if ENV['LOGRAGE_ENABLED'] == '1'
      config.log_formatter = SimpleJsonFormatter.new
    end

    config.active_job.queue_adapter = :resque

    # Redis configurations. Defaults to a localhost instance.
    config.redis_host      = ENV['MCONF_REDIS_HOST']
    config.redis_port      = ENV['MCONF_REDIS_PORT']
    config.redis_db        = ENV['MCONF_REDIS_DB']
    config.redis_password  = ENV['MCONF_REDIS_PASSWORD']

    # Prevent errors when precompiling assets in local production
    if ENV['RAILS_ENV'] == 'development'
      config.assets.configure do |env|
        env.export_concurrent = false
      end
    end
  end
end
