class CreateSearchLogs < ActiveRecord::Migration[5.2]
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
      t.text    :referer,     null: true
      t.string  :referral,    null: false, default: ''
      t.string  :channel,     null: false, default: ''

      t.string  :medium,      null: false, default: ''
      t.string  :ab_test,     null: false, default: ''

      t.datetime :created_at, null: false

      t.index :action
      t.index :created_at
      t.index [:uid, :action]
    end
  end
end
