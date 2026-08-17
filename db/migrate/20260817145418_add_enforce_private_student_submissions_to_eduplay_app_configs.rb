class AddEnforcePrivateStudentSubmissionsToEduplayAppConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :eduplay_app_configs, :enforce_private_student_submissions, :boolean, default: false, null: false
  end
end
