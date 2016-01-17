class CreateBackgroundSearchLogs < ActiveRecord::Migration
  def change
    create_table :background_search_logs do |t|
      t.boolean :login,         default: false
      t.integer :login_user_id, default: -1
      t.text :uid,              default: -1
      t.boolean :status,        default: false
      t.text :reason,           default: ''

      t.timestamps null: false
    end
    add_index :background_search_logs, :login_user_id
    add_index :background_search_logs, :uid
  end
end
