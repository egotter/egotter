class CreatePersonalityInsights < ActiveRecord::Migration[5.2]
  def change
    create_table :personality_insights do |t|
      t.bigint :uid, null: false
      t.json :profile

      t.timestamps null: false

      t.index :uid, unique: true
      t.index :created_at
    end
  end
end
