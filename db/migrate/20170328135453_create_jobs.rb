class CreateJobs < ActiveRecord::Migration[4.2]
  def change
    create_table :jobs do |t|
      t.integer  :track_id,        null: false, default: -1
      t.integer  :user_id,         null: false, default: -1
      t.integer  :uid,             null: false, default: -1, limit: 8
      t.string   :screen_name,     null: false, default: ''
      t.integer  :twitter_user_id, null: false, default: -1
      t.integer  :client_uid,      null: false, default: -1, limit: 8

      t.string   :jid,             null: false, default: ''
      t.string   :parent_jid,      null: false, default: ''
      t.string   :worker_class,    null: false, default: ''
      t.string   :error_class,     null: false, default: ''
      t.string   :error_message,   null: false, default: ''
      t.datetime :enqueued_at,     null: true,  default: nil
      t.datetime :started_at,      null: true,  default: nil
      t.datetime :finished_at,     null: true,  default: nil

      t.timestamps null: false
    end

    add_index :jobs, :track_id
    add_index :jobs, :uid
    add_index :jobs, :screen_name
    add_index :jobs, :jid
    add_index :jobs, :created_at
  end
end
