class CreateCreatePeriodicReportRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :create_periodic_report_requests do |t|
      t.integer  :user_id,      null: false
      t.string   :requested_by, null: true, default: nil
      t.string   :status,       null: false, default: ''
      t.datetime :finished_at,  null: true, default: nil

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
