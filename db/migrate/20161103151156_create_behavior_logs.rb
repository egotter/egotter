class CreateBehaviorLogs < ActiveRecord::Migration
  def change
    create_table :behavior_logs do |t|
      t.string  :session_id,  null: false, default: ''
      t.integer :user_id,     null: false, default: -1, index: true
      t.string  :uid,         null: false, default: -1, index: true
      t.string  :screen_name, null: false, default: '', index: true
      t.text    :json

      t.timestamps null: false
    end

    add_index :behavior_logs, :session_id, unique: true
  end
end
