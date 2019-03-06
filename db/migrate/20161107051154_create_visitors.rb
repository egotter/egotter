class CreateVisitors < ActiveRecord::Migration[4.2]
  def change
    create_table :visitors do |t|
      t.string   :session_id,      null: false
      t.integer  :user_id,         null: false, default: -1
      t.string   :uid,             null: false, default: -1
      t.string   :screen_name,     null: false, default: ''
      t.datetime :first_access_at, null: true
      t.datetime :last_access_at,  null: true

      t.timestamps null: false

      t.index :session_id, unique: true
      t.index :user_id
      t.index :uid
      t.index :screen_name
      t.index :first_access_at
      t.index :last_access_at
      t.index :created_at
    end
  end
end
