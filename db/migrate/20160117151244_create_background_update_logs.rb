class CreateBackgroundUpdateLogs < ActiveRecord::Migration
  def change
    create_table :background_update_logs do |t|
      t.string :uid,     null: false, default: -1
      t.string :bot_uid, null: false, default: -1
      t.boolean :status, null: false, default: false
      t.string :reason,  null: false, default: ''
      t.text :message,   null: false

      t.timestamps null: false
    end
    add_index :background_update_logs, :uid
    add_index :background_update_logs, :created_at
  end
end
