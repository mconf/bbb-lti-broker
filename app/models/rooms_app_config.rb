class RoomsAppConfig < ApplicationRecord
  belongs_to :tool, class_name: 'RailsLti2Provider::Tool'

  validates :moodle_url,
            format: {
              # Anchored at both ends: \A alone only checks that the string
              # starts with https://, so a newline could carry a second line
              # past a validation that is meant to pin the scheme.
              with: /\Ahttps:\/\/[^\n\r]*\z/i,
              message: ->(_object, _data) {
                I18n.t(
                  'errors.messages.rooms_app_config.moodle_url_https_only',
                  default: 'permite apenas URLs que começam com https://'
                )
              }
            },
            allow_blank: true

  validates :moodle_presence_threshold_percentage,
            :moodle_partial_presence_threshold_percentage,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100,
              message: ->(_object, _data) {
                I18n.t(
                  'errors.messages.rooms_app_config.percentage_out_of_range',
                  default: 'deve ser um número inteiro entre 0 e 100'
                )
              }
            }

  validate :partial_presence_threshold_within_presence_threshold

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

  after_save :log_moodle_url_update, if: :saved_change_to_moodle_url?

  private

  # A partial presence threshold above the full presence threshold leaves no range for partial
  # presence: everyone below the full threshold would be marked absent, silently
  def partial_presence_threshold_within_presence_threshold
    # nothing to compare while either value is not a valid percentage on its own
    return if errors[:moodle_presence_threshold_percentage].any? ||
              errors[:moodle_partial_presence_threshold_percentage].any?

    partial = self.moodle_partial_presence_threshold_percentage
    full = self.moodle_presence_threshold_percentage
    return if partial.blank? || full.blank? || partial <= full

    errors.add(
      :moodle_partial_presence_threshold_percentage,
      I18n.t(
        'errors.messages.rooms_app_config.partial_presence_threshold_above_presence',
        default: 'não pode ser maior que o percentual mínimo para presença cheia'
      )
    )
  end

  def log_moodle_url_update
    old_url, new_url = saved_change_to_moodle_url

    Rails.logger.info(
      "[Security] moodle_url updated from #{sanitize_moodle_url(old_url)} to #{sanitize_moodle_url(new_url)}"
    )
  end

  def sanitize_moodle_url(url)
    return 'blank' if url.blank?

    uri = URI.parse(url)
    sanitized = "#{uri.scheme}://#{uri.host}"
    sanitized += ":#{uri.port}" if uri.port && ![80, 443].include?(uri.port)
    sanitized
  rescue URI::InvalidURIError
    url.to_s.sub(%r{\?.*}, '').sub(%r{#.*}, '')
  end

end
