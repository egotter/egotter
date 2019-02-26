class CreateSearchErrorLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :search_error_logs do |t|
      t.string  :session_id,  null: false, default: '', index: true
      t.integer :user_id,     null: false, default: -1, index: true
      t.string  :uid,         null: false, default: '', index: true
      t.string  :screen_name, null: false, default: '', index: true

      t.string  :location,    null: false, default: ''
      t.string  :message,     null: false, default: ''

      t.string  :controller,  null: false, default: ''
      t.string  :action,      null: false, default: ''
      t.string  :method,      null: false, default: ''
      t.string  :path,        null: false, default: ''
      t.integer :status,      null: false, default: -1
      t.string  :via,         null: false, default: ''

      t.string  :device_type, null: false, default: ''
      t.string  :os,          null: false, default: ''
      t.string  :browser,     null: false, default: ''
      t.string  :user_agent,  null: false, default: ''
      t.string  :referer,     null: false, default: ''

      t.datetime :created_at, null: false, index: true
    end
  end
end
