class CreateSearchLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :search_logs do |t|
      t.string  :session_id,  null: false, default: '', index: true
      t.integer :user_id,     null: false, default: -1, index: true
      t.bigint  :uid,         null: false, default: -1, index: true
      t.string  :screen_name, null: false, default: '', index: true

      t.string  :controller,  null: false, default: ''
      t.string  :action,      null: false, default: ''
      t.boolean :cache_hit,   null: false, default: false
      t.boolean :ego_surfing, null: false, default: false
      t.string  :method,      null: false, default: ''
      t.string  :path,        null: false, default: ''
      t.integer :status,      null: false, default: -1
      t.string  :via,         null: false, default: ''

      t.string  :device_type, null: false, default: ''
      t.string  :os,          null: false, default: ''
      t.string  :browser,     null: false, default: ''
      t.string  :user_agent,  null: false, default: ''
      t.string  :referer,     null: false, default: ''
      t.string  :referral,    null: false, default: ''
      t.string  :channel,     null: false, default: ''

      t.boolean :first_time,  null: false, default: false
      t.boolean :landing,     null: false, default: false
      t.boolean :bouncing,    null: false, default: false
      t.boolean :exiting,     null: false, default: false
      t.string  :medium,      null: false, default: ''
      t.string  :ab_test,     null: false, default: ''

      t.datetime :created_at, null: false
    end
    add_index :search_logs, :action
    add_index :search_logs, :created_at
    add_index :search_logs, [:uid, :action]
  end
end
