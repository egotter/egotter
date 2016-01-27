class CreateFriends < ActiveRecord::Migration
  def change
    create_table :friends do |t|
      t.string :uid,         null: false
      t.string :screen_name, null: false
      t.text :user_info,     null: false
      t.integer :from_id,    null: false

      t.timestamps null: false
    end
    add_index :friends, :uid
    add_index :friends, :from_id
    add_index :friends, :screen_name
  end
end
