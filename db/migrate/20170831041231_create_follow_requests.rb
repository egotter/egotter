class CreateFollowRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :follow_requests do |t|
      t.integer  :user_id,       null: false
      t.bigint   :uid,           null: false
      t.string   :requested_by,  null: false, default: ''
      t.string   :error_class,   null: false, default: ''
      t.string   :error_message, null: false, default: ''
      t.datetime :finished_at,   null: true,  default: nil

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
