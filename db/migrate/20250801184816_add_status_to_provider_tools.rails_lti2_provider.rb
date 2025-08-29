# frozen_string_literal: true

# This migration comes from rails_lti2_provider (originally 20240223142223)
class AddStatusToProviderTools < ActiveRecord::Migration[6.1]
  def self.up
    add_column(:rails_lti2_provider_tools, :status, :integer, null: false, default: 1, if_not_exists: true)
    RailsLti2Provider::Tool.update_all(status: 'enabled') # rubocop:disable Rails/SkipsModelValidations
  end

  def self.down
    remove_column(:rails_lti2_provider_tools, :status)
  end
end
