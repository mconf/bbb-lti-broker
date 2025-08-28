class AddInstitutionGuidToTenants < ActiveRecord::Migration[8.0]
  def change
    add_column(:rails_lti2_provider_tenants, :institution_guid, :string, if_not_exists: true)
    add_index(:rails_lti2_provider_tenants, :institution_guid, unique: true, if_not_exists: true)
  end
end
