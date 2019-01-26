class CreateFollowRequests < ActiveRecord::Migration
  def change
    create_table :follow_requests do |t|
      t.integer :user_id, null: false
      t.bigint :uid, null: true

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
