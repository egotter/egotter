class CreateDeleteTweetsBySearchRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :delete_tweets_by_search_requests do |t|
      t.integer  :user_id,            null: false
      t.integer  :reservations_count, null: false, default: 0
      t.integer  :deletions_count,    null: false, default: 0
      t.integer  :errors_count,       null: false, default: 0
      t.boolean  :send_dm,            null: false, default: false
      t.boolean  :post_tweet,         null: false, default: false
      t.text     :error_message,      null: true
      t.json     :filters
      t.json     :tweet_ids
      t.datetime :started_at,         null: true, default: nil
      t.datetime :stopped_at,         null: true, default: nil
      t.datetime :finished_at,        null: true, default: nil

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
