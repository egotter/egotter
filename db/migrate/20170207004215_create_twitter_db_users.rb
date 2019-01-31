class CreateTwitterDbUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :twitter_db_users, id: false, options: 'ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4' do |t|
      t.column  :id,            'BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT'
      t.integer :uid,            null: false, limit: 8
      t.string  :screen_name,    null: false, index: true
      t.integer :friends_size,   null: false, default: 0
      t.integer :followers_size, null: false, default: 0
      t.text    :user_info,      null: false

      t.timestamps null: false
    end
    add_index :twitter_db_users, :uid, unique: true
    add_index :twitter_db_users, :created_at
  end
end
