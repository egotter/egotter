class CreateStripeDbEvents < ActiveRecord::Migration
  def change
    create_table :stripe_events do |t|
      t.string  :event_id,        null: false
      t.string  :event_type,      null: false
      t.string  :idempotency_key, null: false

      t.timestamps null: false
    end
    add_index :stripe_events, :event_id
    add_index :stripe_events, :idempotency_key, unique: true
    add_index :stripe_events, :created_at
  end
end
