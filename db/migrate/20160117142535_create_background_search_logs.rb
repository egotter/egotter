class CreateBackgroundSearchLogs < ActiveRecord::Migration
  def change
    create_table :background_search_logs do |t|
      t.boolean :login,         null: false, default: false
      t.integer :login_user_id, null: false, default: -1
      t.string :uid,            null: false, default: -1
      t.string :bot_uid,        null: false, default: -1
      t.boolean :status,        null: false, default: false
      t.string :reason,         null: false, default: ''

      t.timestamps null: false
    end
    add_index :background_search_logs, :login_user_id
    add_index :background_search_logs, :uid
  end
end
