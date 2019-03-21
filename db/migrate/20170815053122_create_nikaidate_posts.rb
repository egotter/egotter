class CreateNikaidatePosts < ActiveRecord::Migration
  def change
    create_table :nikaidate_posts do |t|
      t.string    :archive_id,       null: false
      t.string    :url,              null: false
      t.string    :title,            null: false
      t.text      :description,      null: false
      t.text      :tags_json,        null: false
      t.text      :status_urls_json, null: false
      t.timestamp :published_at,     null: false

      t.timestamps null: false
    end
    add_index :nikaidate_posts, :archive_id, unique: true
    add_index :nikaidate_posts, :published_at
    add_index :nikaidate_posts, :created_at
  end
end
