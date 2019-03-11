class CreateResetCacheLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :reset_cache_logs do |t|
      t.string  :session_id,    null: false, default: -1
      t.integer :user_id,       null: false, default: -1
      t.integer :request_id,    null: false, default: -1
      t.bigint  :uid,           null: false, default: -1
      t.string  :screen_name,   null: false, default: ''
      t.boolean :status,        null: false, default: false
      t.string  :message,       null: false, default: ''
      t.string  :error_class,   null: false, default: ''
      t.string  :error_message, null: false, default: ''

      t.datetime :created_at, null: false

      t.index :created_at
    end
  end
end
