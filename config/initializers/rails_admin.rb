# frozen_string_literal: true

RailsAdmin.config do |config|
  config.main_app_name = 'Broker'

  config.asset_source = :sprockets

  # To avoid CSRF errors
  config.forgery_protection_settings = { with: :null_session }

  # If true, you must authenticate to use rails admin
  if Mconf::Env.fetch_boolean('AUTHENTICATION_RAILS_ADMIN', true)
    config.authorize_with do
      authenticate_or_request_with_http_basic('Administration') do |username, password|
        username == Mconf::Env.fetch('ADMIN_KEY') && password == Mconf::Env.fetch('ADMIN_PASSWORD')
      end
    end
  end

  ###### Actions configs
  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
  end

  config.excluded_models = ['RailsLti2Provider::Registration']

  ###### Model configs
  ### Doorkeeper::Application ###
  config.model Doorkeeper::Application do
    configure :confidential do
      help 'Application will be used where the client secret can be kept confidential. ' \
      'Native mobile apps and Single Page Apps are considered non-confidential.'
    end
    configure :scopes do
      help 'Separate scopes with spaces. Leave blank to use the default scopes.'
    end
    configure :authorized_applications do
      hide
    end
  end
  ### Doorkeeper::Application ###


  ### BbbConfig ###
  config.model BbbConfig do
    label 'BBB Config'

    list do
      configure [:created_at, :updated_at] do
        hide
      end
    end

    edit do
      configure :tool do
        hide
      end
    end
  end
  ### BbbConfig ###


  ### RoomsAppConfig ###
  config.model RoomsAppConfig do
    list do
      configure [:created_at, :updated_at] do
        hide
      end
    end

    show do
      configure [:created_at, :updated_at]
    end

    edit do
      configure :tool do
        hide
      end

      include_all_fields
      group :default do
      end

      # Moodle Configs
      group :moodle_configs do
        active false

        field :moodle_integration_enabled do
          label 'Moodle integration enabled'
          help 'If disabled, the Moodle configs are not sent. The MoodleToken is destroyed in Rooms database.'
        end
        field :moodle_url do
          label 'API URL'
        end
        field :moodle_token do
          label 'API Token'
        end
        field :moodle_group_select_enabled do
          label 'Group select enabled'
        end
        field :moodle_show_all_groups do
          label 'Show all groups'
        end
      end

      # Brightspace Configs
      group :brightspace_configs do
        label 'Brightspace configs'
        active false

        field :brightspace_integration_enabled do
          label 'Brightspace integration enabled'
          help 'If disabled, the Brightspace configs are not sent. The ConsumerConfigBrightspaceOauth is destroyed in Rooms database.'
        end
        field :brightspace_oauth_url do
          label 'Brightspace URL'
        end
        field :brightspace_oauth_client_id do
          label 'Client ID'
        end
        field :brightspace_oauth_client_secret do
          label 'Client secret'
        end
        field :brightspace_oauth_scopes do
          label 'OAuth scopes'
        end
      end
    end
  end
  ### RoomsAppConfig ###


  ### WorkaAppConfig ###
  config.model WorkaAppConfig do
    list do
      configure [:created_at, :updated_at] do
        hide
      end
    end

    show do
      configure [:created_at, :updated_at]
    end

    edit do
      configure :tool do
        hide
      end
    end
  end
  ### WorkaAppConfig ###


  ### EduplayAppConfig ###
  config.model EduplayAppConfig do
    list do
      configure [:created_at, :updated_at] do
        hide
      end
    end

    show do
      configure [:created_at, :updated_at]
    end

    edit do
      configure :tool do
        hide
      end
    end
  end
  ### EduplayAppConfig ###


  ### RsaKeyPair ###
  config.model RsaKeyPair do
    label 'RSA Key Pair'
  end
  ### RsaKeyPair ###


  ### Tenant ###
  config.model 'RailsLti2Provider::Tenant' do
    object_label_method do
      :uid
    end
    configure :uid do
      label 'UID'
    end

    configure [:settings, :metadata] do
      hide
    end

    list do
      configure [:created_at, :updated_at] do
        hide
      end
    end
    create do
      configure :tools do
        hide
      end
    end
    edit do
      configure :tools do
        hide
      end
    end
  end
  ### Tenant ###


  ### Tool ###
  config.model 'RailsLti2Provider::Tool' do
    object_label_method do
      :uuid
    end

    configure :uuid do
      label 'UUID'
    end

    configure :app_settings do
      hide
    end

    edit do
      configure :lti_version, :enum do
        # This block must return an array of strings
        enum do
          ['LTI-1p0', '1.3.0']
        end
        default_value 'LTI-1p0'
      end

      configure :tool_settings do
        default_value 'none'
        hide
      end

      configure [:lti_launches, :registrations] do
        hide
      end

      configure :tenant do
        inline_add false
        inline_edit false
      end

      configure :shared_secret, :string
    end

    create do
      configure :expired_at do
        hide
      end
    end

    list do
      configure [:created_at, :updated_at, :tool_settings, :app_settings, :lti_launches, :registrations] do
        hide
      end
    end

    show do
      configure [:tool_settings, :app_settings, :lti_launches] do
        hide
      end
      configure [:created_at, :updated_at]
      configure :worka_app_configs_for_launch, :json
      configure :eduplay_app_configs_for_launch, :json
      configure :rooms_app_configs_for_launch, :json
    end
  end
  ### Tool ###
end
