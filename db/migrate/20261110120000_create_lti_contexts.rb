class CreateLtiContexts < ActiveRecord::Migration[8.1]
  def change
    create_table :lti_contexts, if_not_exists: true do |t|
      t.bigint :tool_id, null: false
      t.string :app, null: false
      t.string :context_id, null: false, default: ''
      t.string :resource_link_id, null: false, default: ''
      t.string :rooms_handler
      t.string :oauth_consumer_key
      t.string :tool_consumer_instance_guid
      t.string :context_title
      t.string :resource_link_title
      t.string :lti_version
      t.boolean :groups_scoping, default: false, null: false
      t.datetime :last_launch_at, null: false
      t.timestamps
    end
    add_index :lti_contexts, [:app, :tool_id, :context_id, :resource_link_id], unique: true, name: 'index_lti_contexts_on_launch_target', if_not_exists: true
    add_index :lti_contexts, :tool_id, if_not_exists: true
    add_index :lti_contexts, :rooms_handler, if_not_exists: true
    add_foreign_key :lti_contexts, :rails_lti2_provider_tools, column: :tool_id, on_delete: :cascade, if_not_exists: true
  end
end
