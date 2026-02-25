class AddAllowStudentSchedulingToRoomsAppConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms_app_configs, :allow_student_scheduling, :boolean, default: false, null: false
  end
end
