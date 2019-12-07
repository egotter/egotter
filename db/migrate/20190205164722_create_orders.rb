class CreateOrders < ActiveRecord::Migration[5.1]
  def change
    create_table :orders do |t|
      t.integer :user_id,                 null: false
      t.string  :email,                   null: true,  default: nil
      t.string  :name,                    null: true,  default: nil
      t.integer :price,                   null: true,  default: nil
      t.integer :search_count,            null: false, default: 0
      t.integer :follow_requests_count,   null: false, default: 0
      t.integer :unfollow_requests_count, null: false, default: 0
      t.string  :customer_id,             null: true
      t.string  :subscription_id,         null: true
      t.datetime :canceled_at,            null: true,  default: nil

      t.timestamps null: false

      t.index :user_id
    end
  end
end
