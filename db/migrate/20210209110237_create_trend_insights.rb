class CreateTrendInsights < ActiveRecord::Migration[6.0]
  def change
    create_table :trend_insights do |t|
      t.bigint :trend_id, null: false
      t.json :words_count
      t.json :times_count

      t.timestamps null: false

      t.index :trend_id, unique: true
      t.index :created_at
    end
  end
end
