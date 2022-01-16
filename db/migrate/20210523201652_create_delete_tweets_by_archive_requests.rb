class CreateDeleteTweetsByArchiveRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :delete_tweets_by_archive_requests do |t|
      t.integer  :user_id,            null: false
      t.datetime :since_date,         null: true
      t.datetime :until_date,         null: true
      t.integer  :reservations_count, null: false, default: 0
      t.integer  :deletions_count,    null: false, default: 0
      t.integer  :errors_count,       null: false, default: 0
      t.datetime :started_at,         null: true
      t.datetime :stopped_at,         null: true
      t.datetime :finished_at,        null: true

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
