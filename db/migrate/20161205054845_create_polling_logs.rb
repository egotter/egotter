class CreatePollingLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :polling_logs do |t|
      t.string  :session_id,  null: false, default: '', index: true
      t.integer :user_id,     null: false, default: -1, index: true
      t.string  :uid,         null: false, default: '', index: true
      t.string  :screen_name, null: false, default: '', index: true

      t.string  :action,      null: false, default: ''
      t.boolean :status,      null: false, default: false
      t.float   :time,        null: false, default: 0.0
      t.integer :retry_count, null: false, default: 0

      t.string  :device_type, null: false, default: ''
      t.string  :os,          null: false, default: ''
      t.string  :browser,     null: false, default: ''
      t.string  :user_agent,  null: false, default: ''
      t.string  :referer,     null: false, default: ''
      t.string  :referral,    null: false, default: ''
      t.string  :channel,     null: false, default: ''

      t.datetime :created_at, null: false, index: true
    end
  end
end
