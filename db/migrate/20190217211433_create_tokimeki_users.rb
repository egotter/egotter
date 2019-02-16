class CreateTokimekiUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :tokimeki_users do |t|
      t.bigint :uid,              null: false
      t.string  :screen_name,     null: false
      t.integer :friends_count,   null: false, default: 0
      t.integer :processed_count, null: false, default: 0

      t.timestamps null: false

      t.index :uid, unique: true
      t.index :created_at
    end
  end
end
