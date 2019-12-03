class CreateDeleteTweetsRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :delete_tweets_requests do |t|
      t.string   :session_id,  null: false
      t.integer  :user_id,     null: false
      t.boolean  :tweet,       null: false, default: false
      t.datetime :finished_at, null: true, default: nil

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
