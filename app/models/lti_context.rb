# frozen_string_literal: true

# One row per room (app + handler), refreshed by every real launch into Rooms. The launches
# themselves are deleted after a day, so this is how support finds a client's room by course
# name or handler later on.
class LtiContext < ApplicationRecord
  ROOMS_APP = 'rooms'

  belongs_to :tool, class_name: 'RailsLti2Provider::Tool'

  validates :app, :handler, presence: true

  # message: the launch as the sessions API hands it to the app (see #standarized_message)
  def self.record_launch(tool, app, message)
    return unless app == ROOMS_APP

    handler = rooms_handler(message)
    return if handler.nil?

    upsert(
      {
        tool_id: tool.id,
        app: app,
        handler: handler,
        oauth_consumer_key: message.dig('custom_params', 'oauth_consumer_key'),
        tool_consumer_instance_guid: message['tool_consumer_instance_guid'],
        context_id: message['context_id'],
        context_title: message['context_title'],
        resource_link_id: message['resource_link_id'],
        resource_link_title: message['resource_link_title'],
        lti_version: message['lti_version'],
        groups_scoping: groups_scoping?(message),
        last_launch_at: Time.current,
      },
      unique_by: [:app, :handler]
    )
  end

  # Port of AppLaunch#resource_handler in bbb-app-rooms. Rooms owns this formula: changing it
  # there moves every course to a new room, so a change there must be mirrored here.
  # Returns nil when Rooms itself could not compute it (it fails the launch).
  def self.rooms_handler(message)
    consumer_id = message.dig('custom_params', 'oauth_consumer_key').presence ||
                  message['tool_consumer_instance_guid'].presence ||
                  consumer_domain(message['lis_outcome_service_url'])
    context_id = message['context_id']
    return nil if consumer_id.blank? || context_id.nil?

    groups = groups_scoping?(message) && message['resource_link_id'].present? ? message['resource_link_id'].to_s : ''
    Digest::SHA1.hexdigest("rooms#{consumer_id}#{context_id}#{groups}")
  end

  def self.groups_scoping?(message)
    message.dig('custom_params', 'custom_enable_groups_scoping') == 'true'
  end

  def self.consumer_domain(url)
    URI.parse(url).host
  rescue URI::InvalidURIError
    nil
  end
  private_class_method :consumer_domain
end
