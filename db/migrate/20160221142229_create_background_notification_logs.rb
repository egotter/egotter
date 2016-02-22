class CreateBackgroundNotificationLogs < ActiveRecord::Migration
  def change
    create_table :background_notification_logs do |t|
      t.integer :user_id,     null: false, default: -1
      t.string :uid,          null: false, default: -1
      t.string :screen_name,  null: false, default: ''
      t.boolean :status,      null: false, default: false
      t.string :reason,       null: false, default: ''
      t.text :message,        null: false
      t.string :type,         null: false, default: ''
      t.string :delivered_by, null: false, default: ''
      t.text :text,           null: false

      t.timestamps null: false
    end
    add_index :background_notification_logs, :user_id
    add_index :background_notification_logs, [:user_id, :status]
    add_index :background_notification_logs, :uid
    add_index :background_notification_logs, :screen_name
    add_index :background_notification_logs, :created_at
  end
end
