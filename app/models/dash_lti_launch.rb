# frozen_string_literal: true

# A real launch into an app made from the dash, as if the LMS had sent it: it carries the tool's
# current configs for that app, like any launch. Only for Rooms the room it lands in is known
# beforehand (rooms_handler).
class DashLtiLaunch
  include ActiveModel::Model
  include ActiveModel::Attributes

  ROLES = %w[Instructor Learner].freeze
  # Data and the reports filter dash launches out by this custom param
  MARKER = 'custom_dash_launch'
  USER_CONTEXT = 'dash'

  attribute :tool_id, :integer
  attribute :app, :string, default: LtiContext::ROOMS_APP
  # Shown in the room as typed; the operator (log, user id, marker) is its slug
  attribute :name, :string
  attribute :lti_role, :string, default: 'Instructor'
  # A Rooms room to open: its course and resource link come from the launch history
  attribute :handler, :string
  attribute :context_id, :string
  attribute :context_title, :string
  attribute :resource_link_id, :string
  attribute :resource_link_title, :string
  attribute :groups_scoping, :boolean, default: false
  attribute :tool_consumer_instance_guid, :string

  validates :name, presence: true
  validates :operator, presence: { message: 'needs letters or digits in the name' }, if: -> { name.present? }
  validates :lti_role, inclusion: { in: ROLES }
  validate :tool_exists
  validate :app_registered
  validate :handler_in_history
  validates :context_id, presence: true, unless: -> { handler.present? }

  # Apps a launch can go to: the ones registered in Doorkeeper, which is where the broker finds their URL
  def self.apps
    Doorkeeper::Application.where.not(name: LtiContext::SKIPPED_APP).order(:name).pluck(:name)
  end

  def self.from_context(context)
    new(tool_id: context.tool_id, app: context.app).tap { |launch| launch.target = context }
  end

  # The latest history row with the given Rooms room, in this tool or (tool_id: nil) in any
  def self.find_room(tool_id, handler)
    rooms = LtiContext.where(app: LtiContext::ROOMS_APP, rooms_handler: handler.to_s.strip)
    rooms = rooms.where(tool_id: tool_id) if tool_id
    rooms.order(last_launch_at: :desc).first
  end

  # The history row the launch goes to, if any; its course and resource link replace the typed ones
  attr_reader :target

  def target=(context)
    @target = context
    return if context.nil?

    assign_attributes(
      context_id: context.context_id.presence, context_title: context.context_title,
      resource_link_id: context.resource_link_id.presence, resource_link_title: context.resource_link_title,
      groups_scoping: context.groups_scoping, tool_consumer_instance_guid: context.tool_consumer_instance_guid
    )
  end

  def tool
    @tool = nil if @tool&.id != tool_id
    @tool ||= RailsLti2Provider::Tool.find_by(id: tool_id)
  end

  def operator
    name.to_s.parameterize
  end

  def rooms_handler
    LtiContext.rooms_handler(message) if tool && app == LtiContext::ROOMS_APP
  end

  def user_id
    "#{USER_CONTEXT}-#{operator}"
  end

  # Shaped like the 1.1 launch MessageController stores, so the sessions API hands it to the app the same way
  def message
    custom_params = { 'oauth_consumer_key' => tool.uuid }.merge(tool.app_configs_for_launch(app))
    custom_params['custom_enable_groups_scoping'] = 'true' if groups_scoping
    custom_params[MARKER] = operator
    given, family = name.to_s.strip.split(/\s+/, 2)
    {
      'lti_message_type' => 'basic-lti-launch-request',
      # the tool's version, so the app records where the context really comes from (e.g. meeting metadata)
      'lti_version' => tool.lti_version.presence || 'LTI-1p0',
      'user_id' => user_id,
      'roles' => lti_role,
      'lis_person_name_full' => name.to_s.strip,
      'lis_person_name_given' => given,
      'lis_person_name_family' => family,
      'context_id' => context_id,
      'context_title' => context_title,
      'resource_link_id' => resource_link_id,
      'resource_link_title' => resource_link_title,
      'tool_consumer_instance_guid' => tool_consumer_instance_guid,
      'custom_params' => custom_params,
    }.compact
  end

  # Creates the launch the app will read through the sessions API and the user Doorkeeper will
  # authorize; Rooms refuses the launch unless both carry the same user id.
  def launch!(ip:)
    ActiveRecord::Base.transaction do
      user = User.find_or_initialize_by(context: USER_CONTEXT, uid: user_id)
      user.update!(full_name: message['lis_person_name_full'], first_name: message['lis_person_name_given'],
                   last_name: message['lis_person_name_family'], last_accessed_at: Time.current)
      launch = tool.lti_launches.create!(nonce: SecureRandom.hex(16), message: message.to_json, user_id: user.id)
      DashLaunchLog.create!(operator: operator, tool: tool, app: app, rooms_handler: rooms_handler, role: lti_role, ip: ip)
      launch
    end
  end

  private

  def tool_exists
    errors.add(:tool_id, 'must be a registered tool') unless tool
  end

  def app_registered
    errors.add(:app, 'must be an app registered in the broker') unless self.class.apps.include?(app)
  end

  # Resolves a typed handler into its history row; a handler is a hash, so the course can only come from there
  def handler_in_history
    return if handler.blank? || target&.rooms_handler == handler.strip

    room = self.class.find_room(tool_id, handler) if app == LtiContext::ROOMS_APP
    return self.target = room if room

    elsewhere = self.class.find_room(nil, handler)
    errors.add(:handler, elsewhere ? "belongs to tool #{elsewhere.tool.uuid}, not this one" : 'has no Rooms launch recorded for this tool')
  end
end
