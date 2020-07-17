# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.config.session_store(
  :cookie_store,
  key: '_bbb_lti_broker_session',
  same_site: :none,
  secure: Rails.env.production?
)
