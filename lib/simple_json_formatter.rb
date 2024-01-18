# frozen_string_literal: true

class SimpleJsonFormatter < ActiveSupport::Logger::SimpleFormatter
  @pid = $PID

  class << self
    attr_accessor :pid
  end

  def call(severity, _time, _progname, msg)
    self.class.pid = $PID if self.class.pid != $PID

    log = {
      "@timestamp": Time.now.utc,
      pid: self.class.pid,
      level: severity,
    }

    begin
      # so that lograge's logs aren't double quoted
      msg = JSON.parse(msg)
    rescue StandardError
    end

    log[:message] = msg
    "#{log.to_json}\n"
  end
end
