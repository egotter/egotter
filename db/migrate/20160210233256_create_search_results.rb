class CreateSearchResults < ActiveRecord::Migration
  def change
    create_table :search_results do |t|
      t.string :uid,         null: false
      t.string :screen_name, null: false
      t.text :status_info,   null: false
      t.integer :from_id,    null: false
      t.string :query,       null: false

      t.timestamps null: false
    end
    add_index :search_results, :uid
    add_index :search_results, :from_id
    add_index :search_results, :screen_name
    add_index :search_results, :created_at
  end
end
