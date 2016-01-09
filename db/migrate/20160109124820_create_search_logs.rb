class CreateSearchLogs < ActiveRecord::Migration
  def change
    create_table :search_logs do |t|
      t.boolean :login,         default: false
      t.integer :login_user_id, default: -1
      t.string :search_uid,     default: ''
      t.string :search_sn,      default: ''
      t.string :search_value,   default: ''
      t.string :search_menu,    default: ''
      t.boolean :same_user,     default: false

      t.timestamps null: false
    end
    add_index :search_logs, :login_user_id
    add_index :search_logs, :search_value
    add_index :search_logs, :search_menu
  end
end
