class CreateEduplayAppConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :eduplay_app_configs do |t|
      t.belongs_to :tool
      t.string :client_id
      t.string :client_key
      t.string :eduplay_url
      t.string :eduplay_username
      t.string :eduplay_password

      t.timestamps
    end
  end
end
