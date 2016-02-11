class CreateFavorites < ActiveRecord::Migration
  def change
    create_table :favorites do |t|
      t.string :uid,         null: false
      t.string :screen_name, null: false
      t.text :status_info,   null: false
      t.integer :from_id,    null: false

      t.timestamps null: false
    end
    add_index :favorites, :uid
    add_index :favorites, :from_id
    add_index :favorites, :screen_name
    add_index :favorites, :created_at
  end
end
