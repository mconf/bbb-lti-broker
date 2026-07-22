Rails.application.config.to_prepare do

  RailsLti2Provider::Tenant.class_eval do
    validates :uid, uniqueness: true
    validates :institution_guid, uniqueness: true, allow_nil: true
  end

  RailsLti2Provider::Tool.class_eval do
    validates :uuid, uniqueness: true

    has_one :rooms_app_config, dependent: :destroy
    has_one :worka_app_config, dependent: :destroy
    has_one :eduplay_app_config, dependent: :destroy
    has_one :bbb_config, dependent: :destroy
    accepts_nested_attributes_for :rooms_app_config, :worka_app_config, :eduplay_app_config, :bbb_config

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

    # Prepare configs to be sent as custom_params on Eduplay app launch
    def eduplay_app_configs_for_launch
      configs = {}
      configs.merge!(self.eduplay_app_config&.eduplay_configs || {})
      configs['moodle'] = self.eduplay_app_config&.moodle_configs

      configs.compact
    end
  end

  RailsLti2Provider::LtiLaunch.class_eval do
    # Serialization (to_json/to_xml, e.g. via a dash export that includes
    # associated lti_launches) reads attributes through #send by default, which
    # for :message calls the overridden #message reader above - IMS::LTI::Models::
    # Messages::Message.generate(self[:message]) - not the raw stored value. Some
    # legacy launches have a double-JSON-encoded message (self[:message] is a
    # String, not the expected Hash), which makes .generate raise NoMethodError:
    # undefined method 'key?' for an instance of String, crashing serialization for
    # the whole batch rather than just that one record. Reading the raw attribute
    # here instead is both safe (never triggers that parse) and more useful for an
    # export anyway - the raw stored params, not the wrapper object.
    def read_attribute_for_serialization(key)
      return self[:message] if key.to_s == 'message'

      super
    end
  end

end
