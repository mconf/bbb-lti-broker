class AddExpirationTimeToAppLaunches < ActiveRecord::Migration[6.0]
  def change
    add_column(:app_launches, :expiration_time, :datetime)
  end
end
