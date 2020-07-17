class AddOptimizationIndexes < ActiveRecord::Migration[6.0]
  def up
    name = 'index_app_launches_on_nonce'
    unless index_exists?(:app_launches, :nonce, name: name)
      add_index(:app_launches, :nonce, using: 'btree', name: name)
    end

    name = 'index_oauth_access_tokens_on_revoked_at'
    unless index_exists?(:oauth_access_tokens, :revoked_at, name: name)
      add_index(:oauth_access_tokens, :revoked_at, using: 'btree', name: name)
    end

    name = 'index_rails_lti2_provider_lti_launches_on_tool_id'
    unless index_exists?(:rails_lti2_provider_lti_launches, :tool_id, using: 'btree', name: name)
      add_index(:rails_lti2_provider_lti_launches, :tool_id, using: 'btree', name: name)
    end

    name = 'index_rails_lti2_provider_lti_launches_on_nonce'
    unless index_exists?(:rails_lti2_provider_lti_launches, :nonce, using: 'btree', name: name)
      add_index(:rails_lti2_provider_lti_launches, :nonce, using: 'btree', name: name)
    end
  end

  def down
    name = 'index_app_launches_on_nonce'
    if index_exists?(:app_launches, :nonce, name: name)
      remove_index(:app_launches, name: name)
    end

    name = 'index_oauth_access_tokens_on_revoked_at'
    if index_exists?(:oauth_access_tokens, :revoked_at, name: name)
      remove_index(:oauth_access_tokens, name: name)
    end

    name = 'index_rails_lti2_provider_lti_launches_on_tool_id'
    if index_exists?(:rails_lti2_provider_lti_launches, :tool_id, using: 'btree', name: name)
      remove_index(:rails_lti2_provider_lti_launches, name: name)
    end

    name = 'index_rails_lti2_provider_lti_launches_on_nonce'
    if index_exists?(:rails_lti2_provider_lti_launches, :nonce, using: 'btree', name: name)
      remove_index(:rails_lti2_provider_lti_launches, name: name)
    end
  end
end
