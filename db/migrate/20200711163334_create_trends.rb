class CreateTrends < ActiveRecord::Migration[5.2]
  def change
    create_table :trends do |t|
      t.bigint :woe_id, null: false
      t.integer :rank
      t.integer :tweet_volume
      t.integer :tweets_size, null: true
      t.timestamp :tweets_imported_at, null: true
      t.string :name
      t.json :properties
      t.timestamp :time, null: false
      t.json :words_count
      t.json :times_count
      t.timestamp :created_at, null: false

      t.index :time
      t.index :created_at
    end
  end
end
