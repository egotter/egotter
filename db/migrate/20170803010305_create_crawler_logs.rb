class CreateCrawlerLogs < ActiveRecord::Migration
  def change
    create_table :crawler_logs do |t|
      t.string  :controller,  null: false, default: ''
      t.string  :action,      null: false, default: ''

      t.string  :device_type, null: false, default: ''
      t.string  :os,          null: false, default: ''
      t.string  :browser,     null: false, default: ''

      t.string  :ip,          null: false, default: ''
      t.string  :method,      null: false, default: ''
      t.string  :path,        null: false, default: ''
      t.string  :user_agent,  null: false, default: ''

      t.datetime :created_at, null: false
    end
    add_index :crawler_logs, :created_at
  end
end
