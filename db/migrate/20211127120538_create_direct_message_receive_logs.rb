class CreateDirectMessageReceiveLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :direct_message_receive_logs do |t|
      t.bigint :sender_id, index: true
      t.bigint :recipient_id, index: true
      t.boolean :automated
      t.text :message

      t.datetime :created_at, null: false, index: true

      t.index [:automated, :created_at, :recipient_id, :sender_id], name: 'index_direct_message_receive_logs_on_acrs'
      t.index [:sender_id, :recipient_id, :automated, :created_at], name: 'index_direct_message_receive_logs_on_srac'
    end
  end
end
