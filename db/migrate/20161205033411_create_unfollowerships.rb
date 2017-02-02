class CreateUnfollowerships < ActiveRecord::Migration
  def change
    create_table :unfollowerships, id: false do |t|
      t.column  :id,         'BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT'
      t.integer :from_uid,    limit: 8, index: true, null: false
      t.integer :follower_uid,limit: 8, index: true, null: false
      t.integer :sequence,                           null: false
    end
  end
end
