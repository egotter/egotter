class CreateTrends < ActiveRecord::Migration[5.2]
  def change
    create_table :trends do |t|
      t.bigint :woe_id, null: false
      t.integer :rank
      t.integer :tweet_volume
      t.string :name
      t.json :properties
      t.timestamp :time, null: false

      t.index :time
    end
  end
end
