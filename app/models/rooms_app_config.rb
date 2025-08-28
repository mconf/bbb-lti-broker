class RoomsAppConfig < ApplicationRecord
  belongs_to :tool, class_name: 'RailsLti2Provider::Tool'

  def attributes_for_launch
    self.attributes.except('id', 'created_at', 'updated_at', 'tool_id').compact
  end

  def rooms_configs
    self.attributes_for_launch.reject do |key, _|
      key.start_with?('moodle_') || key.start_with?('brightspace_')
    end
  end

  def moodle_configs
    return nil unless self.moodle_integration_enabled?

    self.attributes_for_launch.except('moodle_integration_enabled')
    .select{ |key, _| key.start_with?('moodle_') }
    .transform_keys { |key| key.delete_prefix('moodle_') }
  end

  def brightspace_configs
    return nil unless self.brightspace_integration_enabled?

    self.attributes_for_launch.except('brightspace_integration_enabled')
    .select{ |key, _| key.start_with?('brightspace_') }
    .transform_keys { |key| key.delete_prefix('brightspace_') }
  end
end
