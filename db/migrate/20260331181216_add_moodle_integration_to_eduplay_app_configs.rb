class AddMoodleIntegrationToEduplayAppConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :eduplay_app_configs, :moodle_integration_enabled, :boolean, default: false, null: false
    add_column :eduplay_app_configs, :moodle_url, :string
    add_column :eduplay_app_configs, :moodle_token, :string
    add_column :eduplay_app_configs, :moodle_group_select_enabled, :boolean, default: false, null: false
    add_column :eduplay_app_configs, :moodle_show_all_groups, :boolean, default: false, null: false
  end
end
