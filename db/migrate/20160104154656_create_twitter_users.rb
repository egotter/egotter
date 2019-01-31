class CreateTwitterUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :twitter_users do |t|
      t.string  :uid,            null: false, index: true
      t.string  :screen_name,    null: false, index: true
      t.integer :friends_size,   null: false, default: 0
      t.integer :followers_size, null: false, default: 0
      t.text    :user_info,      null: false
      t.integer :search_count,   null: false, default: 0
      t.integer :update_count,   null: false, default: 0
      t.integer :user_id,        null: false, default: -1

      t.timestamps null: false
    end
    add_index :twitter_users, [:uid, :user_id]
    add_index :twitter_users, [:screen_name, :user_id]
    add_index :twitter_users, :created_at
  end
end
