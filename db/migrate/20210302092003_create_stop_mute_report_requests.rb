class CreateStopMuteReportRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :stop_mute_report_requests do |t|
      t.integer :user_id, null: false
      t.timestamp :created_at, null: false

      t.index :user_id, unique: true
      t.index :created_at
    end
  end
end
