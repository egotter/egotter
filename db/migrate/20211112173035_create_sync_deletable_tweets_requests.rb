class CreateSyncDeletableTweetsRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :sync_deletable_tweets_requests do |t|
      t.bigint :user_id, null: false

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
