class CreateTwitterTables < ActiveRecord::Migration
  ActiveRecord::Base.establish_connection("twitter_#{Rails.env}".to_sym)

  def up
    create_table :users, id: false, options: 'ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4' do |t|
      t.column  :id,            'BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT'
      t.integer :uid,            null: false, limit: 8
      t.string  :screen_name,    null: false, index: true
      t.integer :friends_size,   null: false, default: 0
      t.integer :followers_size, null: false, default: 0
      t.text    :user_info,      null: false

      t.timestamps null: false
    end
    add_index :users, :uid, unique: true
    add_index :users, :created_at

    create_table :friendships, id: false do |t|
      t.integer :user_uid,   limit: 8, index: true, null: false
      t.integer :friend_uid, limit: 8, index: true, null: false
      t.integer :sequence,                          null: false
    end
    add_index :friendships, %i(user_uid friend_uid), unique: true
    add_foreign_key :friendships, :users, column: :user_uid, primary_key: :uid
    add_foreign_key :friendships, :users, column: :friend_uid, primary_key: :uid

    create_table :followerships, id: false do |t|
      t.integer :user_uid,     limit: 8, index: true, null: false
      t.integer :follower_uid, limit: 8, index: true, null: false
      t.integer :sequence,                            null: false
    end
    add_index :followerships, %i(user_uid follower_uid), unique: true
    add_foreign_key :followerships, :users, column: :user_uid, primary_key: :uid
    add_foreign_key :followerships, :users, column: :follower_uid, primary_key: :uid

  ensure
    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
  end

  def down
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS `friendships`'
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS `followerships`'
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS `users`'

  ensure
    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
  end
end
