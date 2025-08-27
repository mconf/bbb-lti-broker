class CreateBbbConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :bbb_configs, if_not_exists: true do |t|
      t.belongs_to :tool
      t.string :url
      t.string :internal_url
      t.string :secret

      t.timestamps
    end
  end
end
