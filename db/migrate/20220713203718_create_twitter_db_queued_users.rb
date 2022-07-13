class CreateTwitterDBQueuedUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :twitter_db_queued_users do |t|
      t.bigint :uid, null: false
      t.timestamp :processed_at, null: true
      t.timestamps null: false
    end
  end
end
