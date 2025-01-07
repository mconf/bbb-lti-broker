Rails.application.config.to_prepare do

  RailsLti2Provider::Tenant.class_eval do
    def set_app_settings(key_or_hash, value = nil, app_name:)
      if app_name.blank? || Doorkeeper::Application.find_by(name: app_name).nil?
        raise(ArgumentError, 'Invalid app name')
      end
      raise(ArgumentError, 'Key cannot be nil') if key_or_hash.nil?

      new_settings = self.settings[app_name] || {}
      if key_or_hash.is_a?(Hash)
        new_settings = new_settings.merge(key_or_hash)
      else
        new_settings[key_or_hash] = value
      end
      self.settings[app_name] = new_settings

      save
    end

    def remove_app_settings(*keys, app_name:)
      if app_name.blank? || Doorkeeper::Application.find_by(name: app_name).nil?
        raise(ArgumentError, 'Invalid app name')
      end
      raise(ArgumentError, 'At least 1 key must be informed') if keys.blank?

      self.settings[app_name] = self.settings[app_name].except(*keys)

      save
    end
  end

  RailsLti2Provider::Tool.class_eval do
    def set_app_settings(key_or_hash, value = nil, app_name:)
      if app_name.blank? || Doorkeeper::Application.find_by(name: app_name).nil?
        raise(ArgumentError, 'Invalid app name')
      end
      raise(ArgumentError, 'Key cannot be nil') if key_or_hash.nil?

      new_settings = self.app_settings[app_name] || {}
      if key_or_hash.is_a?(Hash)
        new_settings = new_settings.merge(key_or_hash)
      else
        new_settings[key_or_hash] = value
      end
      self.app_settings[app_name] = new_settings

      save
    end

    def remove_app_settings(*keys, app_name:)
      if app_name.blank? || Doorkeeper::Application.find_by(name: app_name).nil?
        raise(ArgumentError, 'Invalid app name')
      end
      raise(ArgumentError, 'At least 1 key must be informed') if keys.blank?

      self.app_settings[app_name] = self.app_settings[app_name].except(*keys)

      save
    end
  end

end
