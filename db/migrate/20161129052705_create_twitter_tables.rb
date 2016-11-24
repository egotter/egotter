class CreateTwitterTables < ActiveRecord::Migration
  ActiveRecord::Base.establish_connection(:twitter)

  def change
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS `friends_users`'
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS `followers_users`'
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS `users`'

    create_table :users, id: false, options: 'ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4' do |t|
      t.column  :uid,            'BIGINT NOT NULL PRIMARY KEY'
      t.string  :screen_name,    null: false
      t.integer :friends_size,   null: false, default: 0
      t.integer :followers_size, null: false, default: 0
      t.text    :user_info,      null: false

      t.timestamps null: false
    end
    add_index :users, :created_at

    create_table :friends_users, id: false do |t|
      t.integer :friend_uid, limit: 8, index: true, null: false
      t.integer :user_uid,   limit: 8, index: true, null: false
    end
    add_index :friends_users, %i(friend_uid user_uid), unique: true
    add_foreign_key :friends_users, :users, column: :user_uid, primary_key: :uid
    add_foreign_key :friends_users, :users, column: :friend_uid, primary_key: :uid

    create_table :followers_users, id: false do |t|
      t.integer :follower_uid, limit: 8, index: true, null: false
      t.integer :user_uid,     limit: 8, index: true, null: false
    end
    add_index :followers_users, %i(follower_uid user_uid), unique: true
    add_foreign_key :followers_users, :users, column: :user_uid, primary_key: :uid
    add_foreign_key :followers_users, :users, column: :follower_uid, primary_key: :uid

  ensure
    ActiveRecord::Base.establish_connection(Rails.env)
  end
end
