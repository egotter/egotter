class CreateTwitterDbFriendships < ActiveRecord::Migration[4.2]
  def change
    create_table :twitter_db_friendships, id: false do |t|
      t.column  :id,        'BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT'
      t.integer :user_uid,   limit: 8, index: true, null: false
      t.integer :friend_uid, limit: 8, index: true, null: false
      t.integer :sequence,                          null: false
    end
    add_index :twitter_db_friendships, %i(user_uid friend_uid), unique: true
    add_foreign_key :twitter_db_friendships, :twitter_db_users, column: :user_uid, primary_key: :uid
    add_foreign_key :twitter_db_friendships, :twitter_db_users, column: :friend_uid, primary_key: :uid
  end
end
