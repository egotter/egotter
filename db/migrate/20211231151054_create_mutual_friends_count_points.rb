class CreateMutualFriendsCountPoints < ActiveRecord::Migration[6.1]
  def change
    create_table :mutual_friends_count_points do |t|
      t.bigint :uid, null: false
      t.integer :value, null: false
      t.timestamp :created_at, null: false

      t.index :uid
      t.index :created_at
      t.index %i(uid created_at)
    end
  end
end
