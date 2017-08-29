class CreateTracks < ActiveRecord::Migration
  def change
    create_table :tracks do |t|
      t.string  :session_id,  null: false, default: ''
      t.integer :user_id,     null: false, default: -1
      t.integer :uid,         null: false, default: -1, limit: 8
      t.string  :screen_name, null: false, default: ''

      t.string  :controller,  null: false, default: ''
      t.string  :action,      null: false, default: ''
      t.boolean :auto,        null: false, default: false

      t.string  :via,         null: false, default: ''
      t.string  :device_type, null: false, default: ''
      t.string  :os,          null: false, default: ''
      t.string  :browser,     null: false, default: ''
      t.string  :user_agent,  null: false, default: ''
      t.string  :referer,     null: false, default: ''
      t.string  :referral,    null: false, default: ''
      t.string  :channel,     null: false, default: ''
      t.string  :medium,      null: false, default: ''

      t.datetime :created_at, null: false
    end

    add_index :tracks, :created_at
  end
end
