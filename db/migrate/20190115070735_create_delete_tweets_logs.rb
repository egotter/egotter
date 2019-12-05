class CreateDeleteTweetsLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :delete_tweets_logs do |t|
      t.integer :request_id,    null: false, default: -1
      t.integer :user_id,       null: false, default: -1
      t.bigint  :uid,           null: false, default: -1
      t.string  :screen_name,   null: false, default: ''
      t.boolean :status,        null: false, default: false
      t.integer :destroy_count, null: false, default: 0
      t.integer :retry_in,      null: false, default: 0
      t.string  :message,       null: false, default: ''
      t.string  :error_class,   null: false, default: ''
      t.string  :error_message, null: false, default: ''

      t.datetime :created_at, null: false

      t.index :created_at
    end
  end
end
