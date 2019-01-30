class CreateBlockFriendships < ActiveRecord::Migration[5.1]
  def change
    create_table :block_friendships do |t|
      t.bigint :from_uid,   index: true, null: false
      t.bigint :friend_uid, index: true, null: false
      t.integer :sequence,               null: false
    end
  end
end
