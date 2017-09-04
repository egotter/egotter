class CreateStripeDbPlans < ActiveRecord::Migration
  def change
    create_table :stripe_plans do |t|
      t.string  :plan_key,          null: false
      t.string  :plan_id,           null: false
      t.string  :name,              null: false
      t.integer :amount,            null: false
      t.integer :trial_period_days, null: false
      t.integer :search_limit,      null: false

      t.timestamps null: false
    end
    add_index :stripe_plans, :plan_key
    add_index :stripe_plans, :plan_id, unique: true
    add_index :stripe_plans, :created_at
  end
end
