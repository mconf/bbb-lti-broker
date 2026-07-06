class AddHideRecordingsHistoryToRoomsAppConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms_app_configs, :hide_recordings_history, :boolean, default: false, null: false

  end
end