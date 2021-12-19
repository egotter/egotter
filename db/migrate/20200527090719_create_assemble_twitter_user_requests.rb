class CreateAssembleTwitterUserRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :assemble_twitter_user_requests do |t|
      t.integer  :twitter_user_id, null: false
      t.bigint   :user_id,         null: true
      t.bigint   :uid,             null: true
      t.string   :status,          null: false, default: ''
      t.string   :requested_by,    null: true, default: nil
      t.datetime :finished_at,     null: true, default: nil

      t.timestamps null: false

      t.index :twitter_user_id
      t.index :created_at
    end
  end
end
