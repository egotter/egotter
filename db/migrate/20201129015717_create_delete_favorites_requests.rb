class CreateDeleteFavoritesRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :delete_favorites_requests do |t|
      t.integer  :user_id,       null: false
      t.boolean  :tweet,         null: false, default: false
      t.integer  :destroy_count, null: false, default: 0
      t.datetime :finished_at,   null: true, default: nil
      t.string   :error_class,   null: false, default: ''
      t.string   :error_message, null: false, default: ''

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
