class CreateCreateUnfollowLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :create_unfollow_logs do |t|
      t.integer  :user_id,         null: true
      t.integer  :request_id,      null: true
      t.bigint   :uid,             null: true
      t.boolean  :status,          null: false, default: false
      t.string   :error_class,     null: true
      t.string   :error_message,   null: true
      t.datetime :created_at,      null: false

      t.index :user_id
      t.index :request_id
      t.index :created_at
    end
  end
end
