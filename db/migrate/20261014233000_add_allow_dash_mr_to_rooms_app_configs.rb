class AddAllowDashMrToRoomsAppConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms_app_configs, :allow_dash_mr, :boolean, default: false, null: false
  end
end
