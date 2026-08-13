class AddPresencePercentageFieldsToRoomsAppConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms_app_configs, :moodle_presence_percentage_enabled, :boolean, default: false, null: false
    add_column :rooms_app_configs, :moodle_presence_threshold_percentage, :integer, default: 75, null: false
    add_column :rooms_app_configs, :moodle_partial_presence_threshold_percentage, :integer, default: 10, null: false
  end
end
