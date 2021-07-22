class AddIndexOnAppLaunchesExpirationTime < ActiveRecord::Migration[6.0]
  def change
    add_index(:app_launches, :expiration_time)
  end
end
