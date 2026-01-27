class EduplayAppConfig < ApplicationRecord
  belongs_to :tool, class_name: 'RailsLti2Provider::Tool'

  def attributes_for_launch
    self.attributes.except('id', 'created_at', 'updated_at', 'tool_id').compact
  end
end
