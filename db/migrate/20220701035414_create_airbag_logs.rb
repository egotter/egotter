class CreateAirbagLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :airbag_logs do |t|
      t.string :severity, null: false
      t.text :message
      t.json :properties
      t.timestamp :time, null: false

      t.index :time
      t.index [:time, :severity]
    end
  end
end
