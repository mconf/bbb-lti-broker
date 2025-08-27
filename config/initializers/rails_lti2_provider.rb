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
  end

end
