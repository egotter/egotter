class CreateUnfriendships < ActiveRecord::Migration
  def change
    create_table :unfriendships, id: false do |t|
      t.integer :friend_id,           index: true, null: false
      t.integer :from_uid,  limit: 8, index: true, null: false
    end
    add_index :unfriendships, %i(from_uid friend_id), unique: true
  end
end
