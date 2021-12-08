class CreateDirectMessageEventLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :direct_message_event_logs do |t|
      t.string :name
      t.bigint :sender_id
      t.bigint :recipient_id
      t.timestamp :time, null: false

      t.index [:name, :time]
      t.index :time
    end
  end
end
