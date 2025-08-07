# frozen_string_literal: true

RailsAdmin.config do |config|
  ### Popular gems integration

  ## == Devise ==
  # config.authenticate_with do
  #   warden.authenticate! scope: :user
  # end
  # config.current_user_method(&:current_user)

  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.asset_source = :sprockets

  # If true, you must authenticate to use rails admin
  if Mconf::Env.fetch_boolean('AUTHENTICATION_RAILS_ADMIN', true)
    config.authorize_with do
      authenticate_or_request_with_http_basic('Administration') do |username, password|
        username == Mconf::Env.fetch('ADMIN_KEY') && password == Mconf::Env.fetch('ADMIN_PASSWORD')
      end
    end
  end

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.included_models = ['RailsLti2Provider::Tool', 'RailsLti2Provider::Tenant'] if Rails.env.production?
end
