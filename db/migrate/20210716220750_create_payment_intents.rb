class CreatePaymentIntents < ActiveRecord::Migration[6.1]
  def change
    create_table :payment_intents do |t|
      t.bigint :user_id, null: false
      t.string :stripe_payment_intent_id, null: false
      t.datetime :expiry_date, null: false
      t.datetime :succeeded_at, null: true
      t.datetime :canceled_at, null: true

      t.timestamps null: false

      t.index :user_id
      t.index :stripe_payment_intent_id, unique: true
    end
  end
end
