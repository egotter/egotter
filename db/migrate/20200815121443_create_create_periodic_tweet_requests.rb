class CreateCreatePeriodicTweetRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :create_periodic_tweet_requests do |t|
      t.integer :user_id, null: false

      t.timestamps null: false

      t.index :user_id, unique: true
      t.index :created_at
    end
  end
end
