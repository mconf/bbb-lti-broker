class RenameAllowDashMrToAllowElosAnalyticsOnRoomsAppConfigs < ActiveRecord::Migration[8.1]
  def change
    rename_column :rooms_app_configs, :allow_dash_mr, :allow_elos_analytics
  end
end
