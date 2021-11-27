class CreateDirectMessageReceiveLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :direct_message_receive_logs do |t|
      t.bigint :sender_id, index: true
      t.bigint :recipient_id, index: true
      t.text :message

      t.datetime :created_at, null: false, index: true
    end
  end
end
