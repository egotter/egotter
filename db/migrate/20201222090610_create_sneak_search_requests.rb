class CreateSneakSearchRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :sneak_search_requests do |t|
      t.integer :user_id, null: false

      t.timestamps null: false

      t.index :user_id, unique: true
      t.index :created_at
    end
  end
end
