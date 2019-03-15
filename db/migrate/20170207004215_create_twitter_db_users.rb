class CreateTwitterDbUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :twitter_db_users, id: false, options: 'ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4' do |t|
      t.column  :id,            'BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT'
      t.integer :uid,             null: false, limit: 8
      t.string  :screen_name,     null: false, index: true
      t.integer :friends_size,    null: false, default: 0
      t.integer :followers_size,  null: false, default: 0
      t.integer :friends_count,   null: false, default: -1
      t.integer :followers_count, null: false, default: -1

      t.string   :name,                    null: false, default: ''
      t.string   :location,                null: false, default: ''
      t.string   :description,             null: false, default: ''
      t.string   :url,                     null: false, default: ''
      t.boolean  :protected,               null: false, default: false
      t.integer  :listed_count,            null: false, default: -1
      t.integer  :favourites_count,        null: false, default: -1
      t.string   :utc_offset,              null: false, default: ''
      t.string   :time_zone,               null: false, default: ''
      t.string   :geo_enabled,             null: false, default: false
      t.boolean  :verified,                null: false, default: false
      t.boolean  :statuses_count,          null: false, default: -1
      t.string   :lang,                    null: false, default: ''
      t.datetime :status_created_at,       null: true
      t.string   :profile_image_url_https, null: false, default: ''
      t.string   :profile_banner_url,      null: false, default: ''
      t.string   :profile_link_color,      null: false, default: ''
      t.boolean  :suspended,               null: false, default: false
      t.text     :entities_text,           null: false, default: ''

      t.text    :user_info,       null: false

      t.timestamps null: false

      t.index :uid, unique: true
      t.index :created_at
    end
  end
end
