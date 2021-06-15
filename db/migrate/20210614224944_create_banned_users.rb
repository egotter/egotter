class CreateBannedUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :banned_users do |t|
      t.bigint :user_id, null: false
      t.timestamp :created_at, null: false

      t.index :user_id, unique: true
      t.index :created_at
    end
  end
end
