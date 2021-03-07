class CreateDirectMessageErrorLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :direct_message_error_logs do |t|
      t.bigint :sender_id, index: true
      t.bigint :recipient_id, index: true
      t.text :error_class
      t.text :error_message
      t.json :properties

      t.datetime :created_at, null: false, index: true
    end
  end
end
