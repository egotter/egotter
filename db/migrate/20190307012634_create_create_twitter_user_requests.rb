class CreateCreateTwitterUserRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :create_twitter_user_requests do |t|
      t.string   :session_id,      null: true
      t.integer  :user_id,         null: false
      t.bigint   :uid,             null: false
      t.integer  :twitter_user_id, null: true
      t.string   :requested_by,    null: false, default: ''
      t.datetime :finished_at,     null: true
      t.bigint   :ahoy_visit_id,   null: true

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
