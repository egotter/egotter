class CreateCustomers < ActiveRecord::Migration[6.1]
  def change
    create_table :customers do |t|
      t.bigint :user_id, null: false
      t.string :stripe_customer_id, null: false

      t.timestamps

      t.index [:user_id, :stripe_customer_id], unique: true
      t.index :created_at
    end
  end
end
