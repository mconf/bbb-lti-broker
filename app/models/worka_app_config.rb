class WorkaAppConfig < ApplicationRecord
  belongs_to :tool, class_name: 'RailsLti2Provider::Tool'

  def attributes_for_launch
    self.attributes.except('id', 'created_at', 'updated_at', 'tool_id').compact
  end

  def saas_configs
    self.attributes_for_launch.select{ |key, _| key.start_with?('saas_') }
  end

  def self_hosted_configs
    self.attributes_for_launch.select{ |key, _| key.start_with?('self_hosted_') }
  end
end
