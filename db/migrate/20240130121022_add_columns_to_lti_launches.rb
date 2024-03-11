class AddColumnsToLtiLaunches < ActiveRecord::Migration[6.1]
  def change
    add_reference(:rails_lti2_provider_lti_launches, :user)
    add_column(:rails_lti2_provider_lti_launches, :expired, :boolean)
  end
end
