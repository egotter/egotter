class CreateBlacklistWords < ActiveRecord::Migration
  def change
    create_table :blacklist_words do |t|
      t.string :text, null: false

      t.timestamps null: false
    end
    add_index :blacklist_words, :text, unique: true
    add_index :blacklist_words, :created_at
  end
end
