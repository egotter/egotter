class CreateWelcomeMessages < ActiveRecord::Migration
  def change
    create_table :welcome_messages do |t|
      t.integer  :user_id,    null: false
      t.datetime :read_at,    null: true
      t.string   :message_id, null: false
      t.string   :token,      null: false

      t.timestamps null: false

      t.index :user_id
      t.index :token, unique: true
      t.index :created_at
    end
  end
end
