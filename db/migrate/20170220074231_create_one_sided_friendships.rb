class CreateOneSidedFriendships < ActiveRecord::Migration
  def change
    create_table :one_sided_friendships, id: false do |t|
      t.column  :id,        'BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT'
      t.integer :from_uid,   limit: 8, index: true, null: false
      t.integer :friend_uid, limit: 8, index: true, null: false
      t.integer :sequence,                          null: false
    end
  end
end
