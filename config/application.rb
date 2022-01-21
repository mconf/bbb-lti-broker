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
    # AppLaunches that are more than {launch_days_to_delete} days old will be deleted
    # every time app_launch is called.
    config.launch_days_to_delete = (ENV['LAUNCH_DAYS_TO_DELETE'] || 15).to_i

    config.app_name = ENV["APP_NAME"] || 'BbbLtiBroker'

    # FIX ME, move this elsewhere
    config.coc_client_id = ENV['COC_CLIENT_ID']
    config.coc_client_secret = ENV['COC_CLIENT_SECRET']
    config.coc_consumer_key = ENV['COC_CONSUMER_KEY']
    config.coc_consumer_secret = ENV['COC_CONSUMER_SECRET']
    config.coc_portal_host = ENV['COC_PASSAPORTE_URI']
    config.coc_package_id = ENV['COC_PACKAGE_ID']

    # use a json formatter to match lograge's logs
    if ENV['LOGRAGE_ENABLED'] == '1'
      config.log_formatter = SimpleJsonFormatter.new
    end
  end
end
