class CreateOrders < ActiveRecord::Migration[5.1]
  def change
    create_table :orders do |t|
      t.integer :user_id,         null: false
      t.integer :search_count,    null: false, default: 0
      t.string  :customer_id,     null: true
      t.string  :subscription_id, null: true

      t.timestamps null: false

      t.index :user_id
    end
  end
end
