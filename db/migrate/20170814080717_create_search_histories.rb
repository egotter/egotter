class CreateSearchHistories < ActiveRecord::Migration
  def change
    create_table :search_histories do |t|
      t.string  :session_id, null: false, default: ''
      t.integer :user_id,    null: false
      t.integer :uid,        null: false, limit: 8
      t.string  :plan_id,    null: true

      t.timestamps null: false
    end
    add_index :search_histories, :session_id
    add_index :search_histories, :user_id
    add_index :search_histories, :created_at
  end
end
