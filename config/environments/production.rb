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

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Compress JavaScripts and CSS.
  Sprockets.register_compressor('application/javascript', :terser, Terser::Compressor)
  config.assets.js_compressor = :terser
  # config.assets.js_compressor = Uglifier.new(harmony: true)
  # config.assets.css_compressor = :sass

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  if ENV['RAILS_SERVE_STATIC_FILES'].present?
    # Disable serving static files from the `/public` folder by default since
    # Apache or NGINX already handles this.
    config.public_file_server.enabled = true

    # Set a cache-control for all assets
    config.public_file_server.headers = {
      'Cache-Control' => 'public, s-maxage=31536000, max-age=31536000',
    }
  end

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  config.action_controller.asset_host = ENV['ASSET_HOST'] if ENV['ASSET_HOST'].present?

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = (ENV['ENABLE_SSL'] == 'true')

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # "info" includes generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV['LOG_LEVEL'] || 'warn'

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "bbb_lti_broker_production"

  # Disable caching for Action Mailer templates even if Action Controller
  # caching is enabled.
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = :notify

  if ENV['LOGRAGE_ENABLED'] != '1'
    # Use default logging formatter so that PID and timestamp are not suppressed.
    config.log_formatter = ::Logger::Formatter.new
  end

  # Log disallowed deprecations.
  config.active_support.disallowed_deprecation = :log

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new "app-name")
  config.action_dispatch.default_headers['X-Frame-Options'] = 'ALLOW-FROM http://localhost'

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    # Disable output buffering when STDOUT isn't a tty (e.g. Docker images, systemd services)
    $stdout.sync = true
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger = logger
  end

  if ENV['RAILS_LOG_REMOTE_NAME'] && ENV['RAILS_LOG_REMOTE_PORT']
    require 'remote_syslog_logger'
    logger_program = ENV['RAILS_LOG_REMOTE_TAG'] || "bbb-lti-broker-#{ENV['RAILS_ENV']}"
    logger = RemoteSyslogLogger.new(ENV['RAILS_LOG_REMOTE_NAME'],
                                    ENV['RAILS_LOG_REMOTE_PORT'], program: logger_program)
    logger.formatter = ::Logger::Formatter.new
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.cache_store = if ENV['REDIS_URL'].present?
                        # Set up Redis cache store
                        [:redis_cache_store,
                          {
                            url: ENV['REDIS_URL'],
                            expires_in: 1.day,
                            connect_timeout: 30, # Defaults to 20 seconds
                            read_timeout: 0.2, # Defaults to 1 second
                            write_timeout: 0.2, # Defaults to 1 second
                            reconnect_attempts: 1, # Defaults to 0
                            error_handler: lambda { |method:, returning:, exception:|
                                              Rails.logger.warn("Support: Redis cache action #{method} failed and returned '#{returning}': #{exception}")
                                            }
                          }
                        ]
                       else
                          [:file_store, Rails.root.join('tmp/cache_store')]
                       end

  config.hosts = ENV['WHITELIST_HOST'].presence || nil

  config.react.variant = :production

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
