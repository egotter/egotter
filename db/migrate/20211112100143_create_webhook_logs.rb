class CreateWebhookLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :webhook_logs do |t|
      t.string :controller
      t.string :action
      t.string :path
      t.json :params
      t.string :ip
      t.string :method
      t.integer :status
      t.string :user_agent

      t.timestamp :created_at, null: false

      t.index :created_at
    end
  end
end
