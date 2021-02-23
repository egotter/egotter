class CreatePeriodicReportReceivedMessageConfirmations < ActiveRecord::Migration[6.0]
  def change
    create_table :periodic_report_received_message_confirmations do |t|
      t.bigint :user_id, null: false
      t.timestamp :created_at, null: false

      t.index :user_id, name: 'index_on_user_id', unique: true
      t.index :created_at, name: 'index_on_created_at'
    end
  end
end
