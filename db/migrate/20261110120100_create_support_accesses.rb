class CreateSupportAccesses < ActiveRecord::Migration[8.1]
  def change
    create_table :support_accesses, if_not_exists: true do |t|
      t.string :operator, null: false
      t.string :kind, null: false
      t.bigint :tool_id
      t.string :app
      t.string :handler
      t.string :role
      t.string :ip
      t.timestamps
    end
    add_index :support_accesses, :tool_id, if_not_exists: true
    add_foreign_key :support_accesses, :rails_lti2_provider_tools, column: :tool_id, on_delete: :nullify, if_not_exists: true
  end
end
