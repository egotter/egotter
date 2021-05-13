class CreateCreateDeletableTweetsRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :create_deletable_tweets_requests do |t|
      t.integer :user_id, null: false

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
