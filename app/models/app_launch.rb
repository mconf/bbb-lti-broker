# frozen_string_literal: true

class AppLaunch < ApplicationRecord
  before_save :set_expiration_time

  def expired?
    self.expiration_time.nil? ||
      self.expiration_time <= DateTime.now.utc
  end

  def invalidate!
    self.update(expiration_time: DateTime.now.utc)
  end

  private

  def set_expiration_time
    self.expiration_time ||= DateTime.now.utc + Rails.configuration.launch_nonce_duration
  end
end
