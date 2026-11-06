class AddAllowLargeMeetingsToRoomsAppConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms_app_configs, :allow_large_meetings, :boolean, default: false, null: false
  end
end
