class CreateStripeWebhookLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :stripe_webhook_logs do |t|
      t.string :controller
      t.string :action
      t.string :path
      t.string :event_id
      t.string :event_type
      t.json :event_data
      t.string :ip
      t.string :method
      t.integer :status
      t.string :user_agent

      t.timestamp :created_at, null: false

      t.index :created_at
    end
  end
end
