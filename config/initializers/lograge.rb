# frozen_string_literal: true

require 'simple_json_formatter'

Rails.application.configure do
  if Mconf::Env.fetch_boolean('LOGRAGE_ENABLED', false)
    config.lograge.enabled = true
    # config.lograge.keep_original_rails_log = false
    config.lograge.formatter = Lograge::Formatters::Logstash.new

    config.lograge.ignore_actions = ['HealthCheckController#show']

    config.lograge.custom_options = lambda do |event|
      params = {}
      unless event.payload[:params].nil?
        params = event.payload[:params].reject do |k|
          %w[controller action commit utf8].include?(k)
        end
        unless params['user'].nil?
          params['user'] = params['user'].reject do |k|
            ['password'].include?(k)
          end
        end
      end

      hash = {
        time: event.time,
        exception: event.payload[:exception], # ["ExceptionClass", "the message"]
        exception_object: event.payload[:exception_object], # the exception instance
      }
      hash.merge!({ 'params' => params }) if params.present?
      hash.merge!({ 'session' => event.payload[:session] }) unless event.payload[:session].nil?
      hash.merge!({ 'user' => event.payload[:user] }) unless event.payload[:user].nil?
      hash.merge!({ 'room' => event.payload[:room] }) unless event.payload[:room].nil?
      hash
    end
  end
end
