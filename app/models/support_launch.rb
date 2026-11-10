# frozen_string_literal: true

# A real launch into Rooms made by support from the dash, as if the LMS had sent it: it lands in
# the room the handler points to and carries the tool's current configs, like any launch.
class SupportLaunch
  include ActiveModel::Model
  include ActiveModel::Attributes

  ROLES = %w[Instructor Learner].freeze
  # Data and the reports filter support launches out by this custom param
  MARKER = 'custom_elos_support'
  USER_CONTEXT = 'elos-support'

  attribute :tool_id, :integer
  attribute :app, :string, default: LtiContext::ROOMS_APP
  attribute :operator, :string
  attribute :display_name, :string, default: -> { Mconf::Env.fetch('SUPPORT_LAUNCH_DEFAULT_NAME', 'Suporte') }
  attribute :lti_role, :string, default: 'Instructor'
  attribute :context_id, :string
  attribute :context_title, :string
  attribute :resource_link_id, :string
  attribute :resource_link_title, :string
  attribute :groups_scoping, :boolean, default: false
  attribute :tool_consumer_instance_guid, :string

  # The operator becomes part of the user id and of the marker, so it is kept to a plain slug
  validates :operator, presence: true, format: { with: /\A[a-z0-9._-]+\z/, message: 'use only lowercase letters, digits, dots, dashes and underscores' }
  validates :display_name, :context_id, presence: true
  validates :lti_role, inclusion: { in: ROLES }
  validate :tool_exists

  def self.from_context(context)
    new(
      tool_id: context.tool_id, app: context.app, context_id: context.context_id, context_title: context.context_title,
      resource_link_id: context.resource_link_id, resource_link_title: context.resource_link_title,
      groups_scoping: context.groups_scoping, tool_consumer_instance_guid: context.tool_consumer_instance_guid
    )
  end

  def tool
    @tool = nil if @tool&.id != tool_id
    @tool ||= RailsLti2Provider::Tool.find_by(id: tool_id)
  end

  def handler
    LtiContext.rooms_handler(message) if tool
  end

  def user_id
    "#{USER_CONTEXT}-#{operator}"
  end

  # Shaped like the 1.1 launch MessageController stores, so the sessions API hands it to Rooms the same way
  def message
    custom_params = { 'oauth_consumer_key' => tool.uuid }.merge(tool.rooms_app_configs_for_launch)
    custom_params['custom_enable_groups_scoping'] = 'true' if groups_scoping
    custom_params[MARKER] = operator
    {
      'lti_message_type' => 'basic-lti-launch-request',
      'lti_version' => 'LTI-1p0',
      'user_id' => user_id,
      'roles' => lti_role,
      'lis_person_name_full' => "#{display_name} (#{operator})",
      'lis_person_name_given' => display_name,
      'lis_person_name_family' => "(#{operator})",
      'context_id' => context_id,
      'context_title' => context_title,
      'resource_link_id' => resource_link_id,
      'resource_link_title' => resource_link_title,
      'tool_consumer_instance_guid' => tool_consumer_instance_guid,
      'custom_params' => custom_params,
    }.compact
  end

  # Creates the launch Rooms will read through the sessions API and the user Doorkeeper will
  # authorize; Rooms refuses the launch unless both carry the same user id.
  def launch!(ip:)
    ActiveRecord::Base.transaction do
      user = User.find_or_initialize_by(context: USER_CONTEXT, uid: user_id)
      user.update!(full_name: message['lis_person_name_full'], first_name: display_name, last_name: "(#{operator})", last_accessed_at: Time.current)
      launch = tool.lti_launches.create!(nonce: SecureRandom.hex(16), message: message.to_json, user_id: user.id)
      SupportAccess.create!(operator: operator, kind: 'launch', tool: tool, app: app, handler: handler, role: lti_role, ip: ip)
      launch
    end
  end

  private

  def tool_exists
    errors.add(:tool_id, 'must be a registered tool') unless tool
  end
end
