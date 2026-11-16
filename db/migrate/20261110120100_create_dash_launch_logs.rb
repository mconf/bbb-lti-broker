class CreateDashLaunchLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :dash_launch_logs, if_not_exists: true do |t|
      t.string :operator, null: false
      t.bigint :tool_id
      t.string :app
      t.string :rooms_handler
      t.string :role
      t.string :ip
      t.timestamps
    end
    add_index :dash_launch_logs, :tool_id, if_not_exists: true
    add_foreign_key :dash_launch_logs, :rails_lti2_provider_tools, column: :tool_id, on_delete: :nullify, if_not_exists: true
  end
end
