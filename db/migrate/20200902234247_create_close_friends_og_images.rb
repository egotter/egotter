class CreateCloseFriendsOgImages < ActiveRecord::Migration[6.0]
  def change
    create_table :close_friends_og_images do |t|
      t.bigint :uid, null: false
      t.json :properties
      t.timestamps null: false

      t.index :uid, unique: true
    end
  end
end
