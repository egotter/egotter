class CreateSlackMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :slack_messages do |t|
      t.string :channel
      t.text :message
      t.json :properties

      t.timestamps null: false

      t.index :created_at
    end
  end
end
