class CreateFollowers < ActiveRecord::Migration
  def change
    create_table :followers do |t|
      t.string :uid,         null: false
      t.string :screen_name, null: false
      t.text :user_info,     null: false
      t.integer :from_id,    null: false

      t.timestamps null: false
    end
    add_index :followers, :uid
    add_index :followers, :from_id
    add_index :followers, :screen_name
    add_index :followers, :created_at
  end
end
