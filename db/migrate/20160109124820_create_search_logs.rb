class CreateSearchLogs < ActiveRecord::Migration
  def change
    create_table :search_logs do |t|
      t.string :session_id,   null: false, default: ''
      t.integer :user_id,     null: false, default: -1
      t.string :uid,          null: false, default: ''
      t.string :screen_name,  null: false, default: ''
      t.string :action,       null: false, default: ''
      t.boolean :ego_surfing, null: false, default: false

      t.timestamps null: false
    end
    add_index :search_logs, :user_id
    add_index :search_logs, :uid
    add_index :search_logs, :screen_name
    add_index :search_logs, :action
    add_index :search_logs, [:uid, :action]
  end
end
