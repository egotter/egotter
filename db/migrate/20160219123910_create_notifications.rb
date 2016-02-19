class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.boolean :email,  null: false, default: true
      t.boolean :dm,     null: false, default: true
      t.boolean :news,   null: false, default: true
      t.boolean :search, null: false, default: true
      t.datetime :last_email_at
      t.datetime :last_dm_at
      t.datetime :last_news_at
      t.datetime :last_search_at
      t.integer :from_id

      t.timestamps null: false
    end
    add_index :notifications, :from_id
  end
end
