class CreateNotificationSettings < ActiveRecord::Migration
  def change
    create_table :notification_settings do |t|
      t.boolean :auto,            null: false, default: true
      t.boolean :email,           null: false, default: true
      t.boolean :dm,              null: false, default: true
      t.boolean :news,            null: false, default: true
      t.boolean :search,          null: false, default: true
      t.datetime :last_email_at,  null: false
      t.datetime :last_dm_at,     null: false
      t.datetime :last_news_at,   null: false
      t.datetime :last_search_at, null: false
      t.integer :from_id,         null: false

      t.timestamps null: false
    end
    add_index :notification_settings, :from_id
  end
end
