class CreateFriendInsights < ActiveRecord::Migration[6.0]
  def change
    create_table :friend_insights do |t|
      t.bigint :uid, null: false
      t.json :profiles_count
      t.json :locations_count

      t.timestamps null: false

      t.index :uid, unique: true
      t.index :created_at
    end
  end
end
