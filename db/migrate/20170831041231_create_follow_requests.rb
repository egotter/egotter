class CreateFollowRequests < ActiveRecord::Migration
  def change
    create_table :follow_requests do |t|
      t.integer :user_id, null: false
      t.bigint :uid, null: true

      t.timestamps null: false
    end

    add_index :follow_requests, :user_id, unique: true
    add_index :follow_requests, :created_at
  end
end
