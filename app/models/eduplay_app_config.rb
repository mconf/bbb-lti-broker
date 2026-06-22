class EduplayAppConfig < ApplicationRecord
  belongs_to :tool, class_name: 'RailsLti2Provider::Tool'

  validates :moodle_url,
            format: {
              with: /\Ahttps:\/\//i,
              message: ->(_object, _data) {
                I18n.t(
                  'errors.messages.eduplay_app_config.moodle_url_https_only',
                  default: 'permite apenas URLs que começam com https://'
                )
              }
            },
            allow_blank: true

  def attributes_for_launch
    self.attributes.except('id', 'created_at', 'updated_at', 'tool_id').compact
  end

  def eduplay_configs
    self.attributes_for_launch.reject do |key, _|
      key.start_with?('moodle_')
    end
  end

  def moodle_configs
    return nil unless self.moodle_integration_enabled?

    self.attributes_for_launch.except('moodle_integration_enabled')
    .select{ |key, _| key.start_with?('moodle_') }
    .transform_keys { |key| key.delete_prefix('moodle_') }
  end
end
