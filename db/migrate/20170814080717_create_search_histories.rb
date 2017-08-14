class CreateSearchHistories < ActiveRecord::Migration
  def change
    create_table :search_histories do |t|
      t.integer :user_id, null: false
      t.integer :uid,     null: false, limit: 8

      t.timestamps null: false
    end
    add_index :search_histories, :user_id
    add_index :search_histories, :created_at
  end
end
