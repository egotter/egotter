class CreateNotificationSettings < ActiveRecord::Migration
  def change
    create_table :notification_settings do |t|
      t.boolean :email,              null: false, default: true
      t.boolean :dm,                 null: false, default: true
      t.boolean :onesignal,          null: false, default: true # add
      t.boolean :news,               null: false, default: true
      t.boolean :search,             null: false, default: true
      t.boolean :update,             null: false, default: true # add

      t.datetime :last_email_at,     null: false
      t.datetime :email_sent_at,     null: true # change

      t.datetime :last_dm_at,        null: false
      t.datetime :dm_sent_at,        null: true # change

      t.datetime :onesignal_sent_at, null: true # add

      t.datetime :last_news_at,      null: false
      t.datetime :news_sent_at,      null: true # change

      t.datetime :last_search_at,    null: false
      t.datetime :search_sent_at,    null: true # change

      t.datetime :update_sent_at,    null: true # add

      t.integer :from_id,            null: false

      t.timestamps null: false
    end
  end

  add_index :notification_settings, :from_id, unique: true
end
