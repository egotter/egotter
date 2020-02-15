class CreateNotificationSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :notification_settings do |t|
      t.integer  :user_id,               null: false
      t.boolean  :email,                 null: false, default: true
      t.boolean  :dm,                    null: false, default: true
      t.boolean  :news,                  null: false, default: true
      t.boolean  :search,                null: false, default: true
      t.boolean  :prompt_report,         null: false, default: true
      t.integer  :report_interval,       null: false, default: 0
      t.boolean  :report_if_changed,     null: false, default: false
      t.boolean  :push_notification,     null: false, default: false
      t.string   :permission_level,      null: true
      t.datetime :last_email_at,         null: true
      t.datetime :last_dm_at,            null: true
      t.datetime :last_news_at,          null: true
      t.datetime :search_sent_at,        null: true
      t.datetime :prompt_report_sent_at, null: true

      t.timestamps null: false
    end
    add_index :notification_settings, :user_id, unique: true
  end
end
