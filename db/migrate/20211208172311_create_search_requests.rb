class CreateSearchRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :search_requests do |t|
      t.bigint :user_id
      t.bigint :uid
      t.string :screen_name
      t.string :status
      t.json :properties
      t.string :error_class
      t.text :error_message

      t.timestamps null: false

      t.index :user_id
      t.index :uid
      t.index :created_at
    end
  end
end
