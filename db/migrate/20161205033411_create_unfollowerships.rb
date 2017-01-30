class CreateUnfollowerships < ActiveRecord::Migration
  def change
    create_table :unfollowerships, id: false do |t|
      t.integer :from_uid,    limit: 8, index: true, null: false
      t.integer :follower_id,           index: true, null: false # TODO remove
      t.integer :follower_uid,limit: 8, index: true, null: false
      t.integer :sequence,                           null: false
    end
    add_index :unfollowerships, %i(from_uid follower_id), unique: true # TODO remove
    add_index :unfollowerships, %i(from_uid follower_uid)
  end
end
