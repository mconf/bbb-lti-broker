Rails.application.config.to_prepare do

  RailsLti2Provider::Tenant.class_eval do
    validates :uid, uniqueness: true
    validates :institution_guid, uniqueness: true, allow_nil: true
  end

  RailsLti2Provider::Tool.class_eval do
    validates :uuid, uniqueness: true

    has_one :rooms_app_config, dependent: :destroy
    has_one :worka_app_config, dependent: :destroy
    has_one :bbb_config, dependent: :destroy
    accepts_nested_attributes_for :rooms_app_config, :worka_app_config, :bbb_config

    after_initialize do
      self.tool_settings ||= 'none'
    end

    # Prepare configs to be sent as custom_params on Rooms app launch
    def rooms_app_configs_for_launch
      configs = { 'institution_guid' => self.tenant.institution_guid }
      configs.merge!(self.rooms_app_config&.rooms_configs || {})
      configs['moodle'] = self.rooms_app_config&.moodle_configs
      configs['brightspace'] = self.rooms_app_config&.brightspace_configs
      configs['bbb'] = self.bbb_config&.attributes_for_launch

      configs.compact
    end

    # Prepare configs to be sent as custom_params on Worka app launch
    def worka_app_configs_for_launch
      configs = { 'institution_guid' => self.tenant.institution_guid }
      configs.merge!(self.worka_app_config&.attributes_for_launch || {})
      configs['bbb'] = self.bbb_config&.attributes_for_launch

      configs.compact
    end
  end

end
