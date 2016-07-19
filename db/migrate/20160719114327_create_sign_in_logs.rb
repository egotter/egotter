class CreateSignInLogs < ActiveRecord::Migration
  def change
    create_table :sign_in_logs do |t|
      t.string  :session_id,  null: false, default: ''
      t.integer :user_id,     null: false, default: -1
      t.string  :context,     null: false, default: ''
      t.string  :device_type, null: false, default: ''
      t.string  :os,          null: false, default: ''
      t.string  :browser,     null: false, default: ''
      t.string  :user_agent,  null: false, default: ''
      t.string  :referer,     null: false, default: ''

      t.datetime :created_at, null: false
    end
    add_index :sign_in_logs, :user_id
    add_index :sign_in_logs, :created_at
  end
end
