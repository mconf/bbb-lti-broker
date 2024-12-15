class AddColumnsToRailsLti2ProviderTenantsAndTools < ActiveRecord::Migration[6.1]
  def change
    add_column(:rails_lti2_provider_tenants, :app_settings, :jsonb, default: {}, null: false)
    add_column(:rails_lti2_provider_tools, :app_settings, :jsonb, default: {}, null: false)
  end
end
