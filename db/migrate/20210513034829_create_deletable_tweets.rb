class CreateDeletableTweets < ActiveRecord::Migration[6.0]
  def change
    create_table :deletable_tweets do |t|
      t.bigint :uid, null: false
      t.bigint :tweet_id, null: false
      t.integer :retweet_count
      t.integer :favorite_count
      t.datetime :tweeted_at, null: false
      t.json :hashtags
      t.json :user_mentions
      t.json :urls
      t.json :media
      t.json :properties

      t.datetime :deleted_at
      t.timestamps null: false

      t.index :tweet_id
      t.index %i(uid tweet_id), unique: true
      t.index :created_at
    end
  end
end
