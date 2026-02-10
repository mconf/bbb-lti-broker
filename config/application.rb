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
    VERSION = '2.0.1'

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    config.eager_load_paths << Rails.root.join('lib')

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.url_host = Mconf::Env.fetch('URL_HOST', 'localhost')

    config.build_number = Mconf::Env.fetch('BUILD_NUMBER', VERSION)

    config.developer_mode_enabled = Mconf::Env.fetch_boolean('DEVELOPER_MODE_ENABLED', false)

    config.relative_url_root = "/#{Mconf::Env.fetch('RELATIVE_URL_ROOT')}"

    config.handler_legacy_patterns = Mconf::Env.fetch('HANDLER_LEGACY_PATTERNS', 'param-resource_link_id,param-oauth_consumer_key')

    config.default_tool = Mconf::Env.fetch('DEFAULT_LTI_TOOL', 'default')

    config.log_level = Mconf::Env.fetch('LOG_LEVEL', :debug)

    config.launch_nonce_duration = Mconf::Env.fetch_int('LAUNCH_NONCE_DURATION', 300).seconds

    # Configures how many days LtiLaunches will be kept on the db.
    # LtiLaunches that are more than {lti_launch_days_to_delete} days old will be deleted
    # every time the RemoveOldLtiLaunchJob runs.
    config.lti_launch_days_to_delete = Mconf::Env.fetch_int('LTI_LAUNCH_DAYS_TO_DELETE', 1)
    config.limit_launch_to_delete = Mconf::Env.fetch_int('LIMIT_LAUNCH_TO_DELETE', 1000)

    config.app_name = Mconf::Env.fetch('APP_NAME', 'BbbLtiBroker')

    # use a json formatter to match lograge's logs
    config.log_formatter = SimpleJsonFormatter.new if Mconf::Env.fetch_boolean('LOGRAGE_ENABLED', false)

    config.active_job.queue_adapter = :resque

    # Redis configurations. Defaults to a localhost instance.
    config.redis_host      = Mconf::Env.fetch('MCONF_REDIS_HOST')
    config.redis_port      = Mconf::Env.fetch('MCONF_REDIS_PORT')
    config.redis_db        = Mconf::Env.fetch('MCONF_REDIS_DB')
    config.redis_password  = Mconf::Env.fetch('MCONF_REDIS_PASSWORD')

    # Prevent errors when precompiling assets in local production
    if Rails.env.development?
      config.assets.configure do |env|
        env.export_concurrent = false
      end
    end
  end
end
