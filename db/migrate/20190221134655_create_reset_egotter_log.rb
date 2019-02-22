class CreateResetEgotterLog < ActiveRecord::Migration[5.1]
  def change
    create_table :reset_egotter_logs do |t|
      t.string  :session_id,  null: false
      t.integer :user_id,     null: false
      t.bigint  :uid,         null: false
      t.string  :screen_name, null: false

      t.boolean :status,      null: false, default: false
      t.string  :message,     null: false, default: ''

      t.string   :error_class,   null: false, default: ''
      t.string   :error_message, null: false, default: ''

      t.datetime :created_at, null: false

      t.index :created_at
    end
  end
end
