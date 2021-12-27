class CreateDeleteTweetsRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :delete_tweets_requests do |t|
      t.string   :session_id,         null: true
      t.string   :request_token,      null: true
      t.integer  :user_id,            null: false
      t.datetime :since_date,         null: true
      t.datetime :until_date,         null: true
      t.boolean  :send_dm,            null: false, default: false
      t.boolean  :tweet,              null: false, default: false
      t.integer  :reservations_count, null: false, default: 0
      t.integer  :destroy_count,      null: false, default: 0
      t.integer  :errors_count,       null: false, default: 0
      t.datetime :started_at,         null: true, default: nil
      t.datetime :stopped_at,         null: true, default: nil
      t.datetime :finished_at,        null: true, default: nil
      t.string   :error_class,        null: false, default: ''
      t.text     :error_message

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
