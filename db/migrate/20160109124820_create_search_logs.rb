class CreateSearchLogs < ActiveRecord::Migration
  def change
    create_table :search_logs do |t|
      t.boolean :login,         null: false, default: false
      t.integer :login_user_id, null: false, default: -1
      t.string :search_uid,     null: false, default: ''
      t.string :search_sn,      null: false, default: ''
      t.string :search_value,   null: false, default: ''
      t.string :search_menu,    null: false, default: ''
      t.boolean :same_user,     null: false, default: false

      t.timestamps null: false
    end
    add_index :search_logs, :login_user_id
    add_index :search_logs, :search_value
    add_index :search_logs, :search_menu
    add_index :search_logs, [:search_uid, :search_menu]
  end
end
