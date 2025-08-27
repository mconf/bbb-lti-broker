class CreateRoomsAppConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms_app_configs, if_not_exists: true do |t|
      t.belongs_to :tool
      t.boolean :set_duration, default: false, null: false
      t.boolean :download_presentation_video, default: true, null: false
      t.boolean :message_reference_terms_use, default: true, null: false
      t.boolean :force_disable_external_link, default: false, null: false
      t.string :external_disclaimer
      t.string :external_widget
      t.string :external_context_url
      t.boolean :moodle_integration_enabled, default: false, null: false
      t.string :moodle_url
      t.string :moodle_token
      t.boolean :moodle_group_select_enabled, default: false, null: false
      t.boolean :moodle_show_all_groups, default: true, null: false
      t.boolean :brightspace_integration_enabled, default: false, null: false
      t.string :brightspace_oauth_url
      t.string :brightspace_oauth_client_id
      t.string :brightspace_oauth_client_secret
      t.string :brightspace_oauth_scopes

      t.timestamps
    end
  end
end
