class CreateSlackLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :slack_logs do |t|
      t.string :channel
      t.text :message
      t.json :properties

      t.timestamp :time, null: false

      t.index :time
    end
  end
end
