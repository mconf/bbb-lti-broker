class AddAutoStartRecordingToRoomsAppConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms_app_configs, :auto_start_recording, :boolean, default: false, null: false
  end
end
