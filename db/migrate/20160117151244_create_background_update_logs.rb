class CreateBackgroundUpdateLogs < ActiveRecord::Migration
  def change
    create_table :background_update_logs do |t|
      t.integer :user_id,    null: false, default: -1
      t.string :uid,         null: false, default: -1
      t.string :screen_name, null: false, default: ''
      t.string :bot_uid,     null: false, default: -1
      t.boolean :status,     null: false, default: false
      t.string :reason,      null: false, default: ''
      t.text :message,       null: false
      t.integer :call_count, null: false, default: -1

      t.datetime :created_at, null: false
    end
    add_index :background_update_logs, :uid
    add_index :background_update_logs, :screen_name
    add_index :background_update_logs, :created_at
  end
end
