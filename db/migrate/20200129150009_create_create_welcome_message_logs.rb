class CreateCreateWelcomeMessageLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :create_welcome_message_logs do |t|
      t.integer :user_id,       null: false, default: -1
      t.integer :request_id,    null: false, default: -1
      t.bigint  :uid,           null: false, default: -1
      t.string  :screen_name,   null: false, default: ''
      t.boolean :status,        null: false, default: false
      t.string  :error_class,   null: false, default: ''
      t.string  :error_message, null: false, default: ''

      t.datetime :created_at,  null: false

      t.index :request_id
      t.index :uid
      t.index :screen_name
      t.index :created_at
    end
  end
end
