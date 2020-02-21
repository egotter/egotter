class CreateCredentialTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :credential_tokens do |t|
      t.integer :user_id, null: false
      t.string :token, null: true
      t.string :secret, null: true
      t.string :instance_id, null: true
      t.string :device_token, null: true

      t.timestamps null: false

      t.index :user_id, unique: true
      t.index :created_at
    end
  end
end
