# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'
require_relative '../lib/simple_json_formatter'

# Load the app's custom environment variables here, so that they are loaded before environments/*.rb

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BbbLtiBroker
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.url_host = ENV['URL_HOST']

    config.build_number = ENV['BUILD_NUMBER'] || 'v1'

    config.log_level = ENV['LOG_LEVEL'] || :debug

    # use a json formatter to match lograge's logs
    if ENV['LOGRAGE_ENABLED'] == '1'
      config.log_formatter = SimpleJsonFormatter.new
    end
  end
end
