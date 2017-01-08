class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships, id: false do |t|
      t.integer :from_id,              index: true, null: false
      t.integer :friend_uid, limit: 8, index: true, null: false
      t.integer :sequence,                          null: false
    end
    add_index :friendships, %i(from_id friend_uid), unique: true
  end
end
