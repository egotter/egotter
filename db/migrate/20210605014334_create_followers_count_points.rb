class CreateFollowersCountPoints < ActiveRecord::Migration[6.0]
  def change
    create_table :followers_count_points do |t|
      t.bigint :uid, null: false
      t.integer :value, null: false
      t.timestamp :created_at, null: false

      t.index :uid
      t.index :created_at
    end
  end
end
