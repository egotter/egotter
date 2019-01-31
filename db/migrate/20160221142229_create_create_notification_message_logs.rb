class CreateCreateNotificationMessageLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :create_notification_message_logs do |t|
      t.integer :user_id,     null: false, index: true
      t.string  :uid,         null: false, index: true
      t.string  :screen_name, null: false, index: true
      t.boolean :status,      null: false, default: false
      t.string  :reason,      null: false, default: ''
      t.text    :message,     null: false
      t.string  :context,     null: false, default: ''
      t.string  :medium,      null: false, default: ''

      t.datetime :created_at, null: false
    end
    add_index :create_notification_message_logs, [:user_id, :status]
    add_index :create_notification_message_logs, :created_at
  end
end
