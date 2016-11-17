class CreatePageCacheLogs < ActiveRecord::Migration
  def change
    create_table :page_cache_logs do |t|
      t.string  :session_id,  null: false, default: ''
      t.integer :user_id,     null: false, default: -1

      t.string  :context,     null: false, default: ''

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
