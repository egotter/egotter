class CreateTokimekiFriendships < ActiveRecord::Migration[5.1]
  def change
    create_table :tokimeki_friendships do |t|
      t.bigint  :user_uid,   index: true, null: false
      t.bigint  :friend_uid, index: true, null: false
      t.integer :sequence,                null: false

      t.index %i(user_uid friend_uid), unique: true
    end

    add_foreign_key :tokimeki_friendships, :tokimeki_users, column: :user_uid, primary_key: :uid
  end
end
