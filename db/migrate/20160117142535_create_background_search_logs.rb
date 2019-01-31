class CreateBackgroundSearchLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :background_search_logs do |t|
      t.string  :session_id,  null: false, default: ''
      t.integer :user_id,     null: false, default: -1
      t.string  :uid,         null: false, default: -1
      t.string  :screen_name, null: false, default: ''

      t.string  :action,      null: false, default: ''
      t.string  :bot_uid,     null: false, default: -1
      t.boolean :auto,        null: false, default: false
      t.boolean :status,      null: false, default: false
      t.string  :reason,      null: false, default: ''
      t.text    :message,     null: false
      t.integer :call_count,  null: false, default: -1
      t.string  :via,         null: false, default: ''

      t.string  :device_type, null: false, default: ''
      t.string  :os,          null: false, default: ''
      t.string  :browser,     null: false, default: ''
      t.string  :user_agent,  null: false, default: ''
      t.string  :referer,     null: false, default: ''
      t.string  :referral,    null: false, default: ''
      t.string  :channel,     null: false, default: ''
      t.string  :medium,      null: false, default: ''

      t.string   :error_class,   null: false, default: ''
      t.string   :error_message, null: false, default: ''

      t.datetime :enqueued_at, null: true,  default: nil
      t.datetime :started_at,  null: true,  default: nil
      t.datetime :finished_at, null: true,  default: nil

      t.datetime :created_at, null: false
    end
    add_index :background_search_logs, :user_id
    add_index :background_search_logs, [:user_id, :status]
    add_index :background_search_logs, :uid
    add_index :background_search_logs, :screen_name
    add_index :background_search_logs, :created_at
  end
end
