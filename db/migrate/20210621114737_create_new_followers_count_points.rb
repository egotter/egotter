class CreateNewFollowersCountPoints < ActiveRecord::Migration[6.0]
  def change
    create_table :new_followers_count_points do |t|
      t.bigint :uid, null: false
      t.integer :value, null: false
      t.timestamp :created_at, null: false

      t.index :uid
      t.index :created_at
      t.index %i(uid created_at)
    end
  end
end
