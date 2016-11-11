class CreateVisitors < ActiveRecord::Migration
  def change
    create_table :visitors do |t|
      t.string  :session_id,  null: false
      t.integer :user_id,     null: false, default: -1, index: true
      t.string  :uid,         null: false, default: -1, index: true
      t.string  :screen_name, null: false, default: '', index: true

      t.timestamps null: false
    end

    add_index :visitors, :session_id, unique: true
    add_index :visitors, :created_at
  end
end
