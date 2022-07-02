class CreateSidekiqLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :sidekiq_logs do |t|
      t.text :message
      t.json :properties
      t.timestamp :time, null: false

      t.index :time
    end
  end
end
