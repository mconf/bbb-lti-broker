class AddColumnToRailsLti2ProviderTools < ActiveRecord::Migration[6.1]
  def change
    add_column(:rails_lti2_provider_tools, :app_settings, :jsonb, default: {}, null: false)
  end
end
