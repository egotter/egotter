class CreateTwitterUsers < ActiveRecord::Migration
  def change
    create_table :twitter_users do |t|
      t.string :uid,           null: false
      t.string :screen_name,   null: false
      t.text :user_info,       null: false
      t.integer :search_count, null: false, default: 0
      t.integer :update_count, null: false, default: 0

      t.timestamps null: false
    end
    add_index :twitter_users, :uid
    add_index :twitter_users, :screen_name
    add_index :twitter_users, :created_at
  end
end
