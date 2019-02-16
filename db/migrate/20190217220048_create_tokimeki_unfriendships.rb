class CreateTokimekiUnfriendships < ActiveRecord::Migration[5.1]
  def change
    create_table :tokimeki_unfriendships do |t|
      t.bigint  :user_uid,   index: true, null: false
      t.bigint  :friend_uid, index: true, null: false
      t.integer :sequence,                null: false
    end
  end
end
