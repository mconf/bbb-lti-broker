# frozen_string_literal: true

# This migration comes from rails_lti2_provider (originally 20240319175531)
class AddMetadataToProviderTenants < ActiveRecord::Migration[6.1]
  def self.up
    add_column(:rails_lti2_provider_tenants, :metadata, :jsonb, null: false, default: {}, if_not_exists: true)
  end

  def self.down
    remove_column(:rails_lti2_provider_tenants, :metadata)
  end
end
