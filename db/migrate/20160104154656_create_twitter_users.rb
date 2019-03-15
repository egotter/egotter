class CreateTwitterUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :twitter_users do |t|
      t.bigint  :uid,             null: false
      t.integer :user_id,         null: false, default: -1
      t.string  :screen_name,     null: false
      t.integer :friends_size,    null: false, default: -1
      t.integer :followers_size,  null: false, default: -1
      t.integer :friends_count,   null: false, default: -1
      t.integer :followers_count, null: false, default: -1
      t.integer :search_count,    null: false, default: 0
      t.integer :update_count,    null: false, default: 0

      t.timestamps null: false

      t.index :uid
      t.index :screen_name
      t.index [:uid, :user_id]
      t.index [:screen_name, :user_id]
      t.index :created_at
    end
  end
end
