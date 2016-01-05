class CreateTwitterUsers < ActiveRecord::Migration
  def change
    create_table :twitter_users do |t|
      t.string :uid,         null: false
      t.string :screen_name, null: false
      t.text :user_info,     null: false

      t.timestamps null: false
    end
    add_index :twitter_users, :uid
    add_index :twitter_users, :screen_name
  end
end
