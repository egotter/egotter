class CreateTwitterDbProfiles < ActiveRecord::Migration[5.2]
  def change
    create_table :twitter_db_profiles do |t|
      t.bigint   :uid,                     null: false
      t.string   :screen_name,             null: false, default: ''
      t.integer  :friends_count,           null: false, default: -1
      t.integer  :followers_count,         null: false, default: -1
      t.boolean  :protected,               null: false, default: false
      t.boolean  :suspended,               null: false, default: false
      t.datetime :status_created_at,       null: true
      t.datetime :account_created_at,      null: true
      t.boolean  :statuses_count,          null: false, default: -1
      t.integer  :favourites_count,        null: false, default: -1
      t.integer  :listed_count,            null: false, default: -1
      t.string   :name,                    null: false, default: ''
      t.string   :location,                null: false, default: ''
      t.string   :description,             null: false, default: ''
      t.string   :url,                     null: false, default: ''
      t.string   :geo_enabled,             null: false, default: false
      t.boolean  :verified,                null: false, default: false
      t.string   :lang,                    null: false, default: ''
      t.string   :profile_image_url_https, null: false, default: ''
      t.string   :profile_banner_url,      null: false, default: ''
      t.string   :profile_link_color,      null: false, default: ''

      t.timestamps null: false

      t.index :uid, unique: true
      t.index :screen_name
      t.index :created_at
    end
  end
end
