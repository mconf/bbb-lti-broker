class CreateWorkaAppConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :worka_app_configs, if_not_exists: true do |t|
      t.belongs_to :tool
      t.boolean :saas_enabled, default: false, null: false
      t.string :saas_world_url
      t.string :saas_map_url
      t.string :saas_map_storage_url
      t.string :self_hosted_url
      t.string :self_hosted_map_url

      t.timestamps
    end
  end
end
