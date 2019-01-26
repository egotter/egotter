class CreateUnfollowRequests < ActiveRecord::Migration
  def change
    create_table :unfollow_requests do |t|
      t.integer :user_id, null: false
      t.bigint :uid, null: false

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
