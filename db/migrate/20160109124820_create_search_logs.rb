class CreateSearchLogs < ActiveRecord::Migration
  def change
    create_table :search_logs do |t|
      t.string  :session_id,  null: false, default: ''
      t.integer :user_id,     null: false, default: -1
      t.string  :uid,         null: false, default: ''
      t.string  :screen_name, null: false, default: ''

      t.string  :action,      null: false, default: ''
      t.boolean :ego_surfing, null: false, default: false
      t.string  :method,      null: false, default: ''

      t.string  :device_type, null: false, default: ''
      t.string  :os,          null: false, default: ''
      t.string  :browser,     null: false, default: ''
      t.string  :user_agent,  null: false, default: ''
      t.string  :referer,     null: false, default: ''
      t.string  :channel,     null: false, default: ''

      t.string  :medium,      null: false, default: ''

      t.datetime :created_at, null: false
    end
    add_index :search_logs, :user_id
    add_index :search_logs, :uid
    add_index :search_logs, :screen_name
    add_index :search_logs, :action
    add_index :search_logs, :created_at
    add_index :search_logs, [:uid, :action]
  end
end
