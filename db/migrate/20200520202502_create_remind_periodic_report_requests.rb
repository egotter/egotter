class CreateRemindPeriodicReportRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :remind_periodic_report_requests do |t|
      t.integer :user_id, null: false

      t.timestamps null: false

      t.index :user_id, unique: true
      t.index :created_at
    end
  end
end
