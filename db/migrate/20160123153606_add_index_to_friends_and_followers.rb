class AddIndexToFriendsAndFollowers < ActiveRecord::Migration
  def change
    add_index :friends, :from_id
    add_index :followers, :from_id
  end
end
