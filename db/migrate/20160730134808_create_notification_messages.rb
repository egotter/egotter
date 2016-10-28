class CreateNotificationMessages < ActiveRecord::Migration
  def change
    create_table :notification_messages do |t|
      t.integer  :user_id,     null: false
      t.string   :uid,         null: false
      t.string   :screen_name, null: false
      t.boolean  :read,        null: false, default: false
      t.datetime :read_at,     null: true
      t.text     :message,     null: false
      t.string   :medium,      null: false, default: ''
      t.string   :token,       null: false, default: ''

      t.timestamps null: false
    end
    add_index :notification_messages, :user_id
    add_index :notification_messages, :uid
    add_index :notification_messages, :screen_name
    add_index :notification_messages, :token
    add_index :notification_messages, :created_at
  end
end
