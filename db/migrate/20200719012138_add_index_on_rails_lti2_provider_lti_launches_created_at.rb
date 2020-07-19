class AddIndexOnRailsLti2ProviderLtiLaunchesCreatedAt < ActiveRecord::Migration[6.0]
  def up
    name = 'index_rails_lti2_provider_lti_launches_on_created_at'
    unless index_exists?(:rails_lti2_provider_lti_launches, :created_at, name: name)
      add_index(:rails_lti2_provider_lti_launches, :created_at, using: 'btree', name: name)
    end
  end

  def down
    name = 'index_rails_lti2_provider_lti_launches_on_created_at'
    if index_exists?(:rails_lti2_provider_lti_launches, :created_at, name: name)
      remove_index(:rails_lti2_provider_lti_launches, name: name)
    end
  end
end
