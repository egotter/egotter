class CreateResetCacheRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :reset_cache_requests do |t|
      t.string   :session_id,  null: false
      t.integer  :user_id,     null: false
      t.datetime :finished_at, null: true, default: nil

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
