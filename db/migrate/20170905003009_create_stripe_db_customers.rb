class CreateStripeDbCustomers < ActiveRecord::Migration
  def change
    create_table :stripe_customers do |t|
      t.integer :uid, null: false, limit: 8
      t.string :customer_id, null: false
      t.string :plan_id

      t.timestamps null: false
    end
    add_index :stripe_customers, :uid, unique: true
    add_index :stripe_customers, :customer_id, unique: true
    add_index :stripe_customers, :created_at
  end
end
