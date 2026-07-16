class AddAllowAiArtifactsToRoomsAppConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms_app_configs, :allow_ai_artifacts, :boolean, default: true, null: false
  end
end
