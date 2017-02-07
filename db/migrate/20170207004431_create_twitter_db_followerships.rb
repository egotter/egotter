class CreateTwitterDbFollowerships < ActiveRecord::Migration
  def change
    create_table :twitter_db_followerships, id: false do |t|
      t.column  :id,          'BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT'
      t.integer :user_uid,     limit: 8, index: true, null: false
      t.integer :follower_uid, limit: 8, index: true, null: false
      t.integer :sequence,                            null: false
    end
    add_index :twitter_db_followerships, %i(user_uid follower_uid), unique: true
    add_foreign_key :twitter_db_followerships, :twitter_db_users, column: :user_uid, primary_key: :uid
    add_foreign_key :twitter_db_followerships, :twitter_db_users, column: :follower_uid, primary_key: :uid
  end
end
