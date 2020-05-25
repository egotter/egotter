class CreatePeriodicReportSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :periodic_report_settings do |t|
      t.integer :user_id,   null: false
      t.boolean :morning,   null: false, default: true
      t.boolean :afternoon, null: false, default: true
      t.boolean :evening,   null: false, default: true
      t.boolean :night,     null: false, default: true
      t.boolean :send_only_if_changed, null: false, default: false

      t.timestamps null: false

      t.index :user_id, unique: true
      t.index :created_at
    end
  end
end
