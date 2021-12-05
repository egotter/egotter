class CreateTwitterApiLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :twitter_api_logs do |t|
      t.string :name

      t.timestamp :created_at, null: false

      t.index :name
      t.index :created_at
    end
  end
end
