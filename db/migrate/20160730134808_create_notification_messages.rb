class CreateNotificationMessages < ActiveRecord::Migration[4.2]
  def change
    create_table :notification_messages do |t|
      t.integer  :user_id,     null: false, index: true
      t.string   :uid,         null: false, index: true
      t.string   :screen_name, null: false, index: true
      t.boolean  :read,        null: false,              default: false
      t.datetime :read_at,     null: true
      t.string   :message_id,  null: false, index: true, default: ''
      t.text     :message,     null: false
      t.string   :context,     null: false,              default: ''
      t.string   :medium,      null: false,              default: ''
      t.string   :token,       null: false, index: true, default: ''

      t.timestamps null: false
    end
    add_index :notification_messages, :created_at
  end
end
