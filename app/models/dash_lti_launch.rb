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
  attribute :operator, :string
  attribute :display_name, :string, default: -> { Mconf::Env.fetch('DASH_LAUNCH_DEFAULT_NAME', 'Suporte') }
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
  validate :app_registered

  # Apps a launch can go to: the ones registered in Doorkeeper, which is where the broker finds their URL
  def self.apps
    Doorkeeper::Application.where.not(name: LtiContext::SKIPPED_APP).order(:name).pluck(:name)
  end

  def self.from_context(context)
    new(
      tool_id: context.tool_id, app: context.app, context_id: context.context_id.presence, context_title: context.context_title,
      resource_link_id: context.resource_link_id.presence, resource_link_title: context.resource_link_title,
      groups_scoping: context.groups_scoping, tool_consumer_instance_guid: context.tool_consumer_instance_guid
    )
  end

  def tool
    @tool = nil if @tool&.id != tool_id
    @tool ||= RailsLti2Provider::Tool.find_by(id: tool_id)
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

  # Creates the launch the app will read through the sessions API and the user Doorkeeper will
  # authorize; Rooms refuses the launch unless both carry the same user id.
  def launch!(ip:)
    ActiveRecord::Base.transaction do
      user = User.find_or_initialize_by(context: USER_CONTEXT, uid: user_id)
      user.update!(full_name: message['lis_person_name_full'], first_name: display_name, last_name: "(#{operator})", last_accessed_at: Time.current)
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
end
