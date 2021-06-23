class CreateCreateDirectMessageRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :create_direct_message_requests do |t|
      t.bigint :sender_id
      t.bigint :recipient_id
      t.text :error_message
      t.json :properties
      t.timestamp :sent_at
      t.timestamp :failed_at

      t.timestamps null: false

      t.index :created_at
      t.index :sender_id
      t.index :recipient_id
    end
  end
end
