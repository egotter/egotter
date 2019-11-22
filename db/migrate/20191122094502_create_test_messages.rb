class CreateTestMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :test_messages do |t|
      t.integer  :user_id,    null: false
      t.datetime :read_at,    null: true
      t.string   :message_id, null: false
      t.string   :message,    null: false, default: ''
      t.string   :token,      null: false

      t.timestamps null: false

      t.index :user_id
      t.index :token, unique: true
      t.index :created_at
    end
  end
end
