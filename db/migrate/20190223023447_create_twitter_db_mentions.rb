class CreateTwitterDbMentions < ActiveRecord::Migration[5.1]
  def change
    # I decided not to compress this table for performance reasons.
    create_table :twitter_db_mentions do |t|
      t.bigint  :uid,            null: false
      t.string  :screen_name,    null: false
      t.integer :sequence,       null: false
      t.text    :raw_attrs_text, null: false

      t.timestamps null: false

      t.index :uid
      t.index :screen_name
      t.index :created_at
    end
  end
end
