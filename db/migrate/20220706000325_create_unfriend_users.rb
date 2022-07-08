class CreateUnfriendUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :unfriend_users do |t|
      t.bigint   :from_uid,           null: false
      t.integer  :sort_order,         null: false
      t.string   :account_status,     null: true
      t.bigint   :uid,                null: false
      t.string   :screen_name,        null: false
      t.integer  :friends_count,      null: false
      t.integer  :followers_count,    null: false
      t.boolean  :protected,          null: false
      t.boolean  :suspended,          null: false
      t.datetime :status_created_at,  null: true
      t.datetime :account_created_at, null: true
      t.integer  :statuses_count,     null: false
      t.integer  :favourites_count,   null: false
      t.integer  :listed_count,       null: false
      t.string   :name,               null: false
      t.string   :location,           null: false
      t.text     :description
      t.string   :url,                null: false
      t.boolean  :verified,           null: false
      t.string   :profile_image_url,  null: false

      t.timestamps null: false

      t.index [:from_uid, :sort_order], unique: true
      t.index :created_at
    end
  end
end
