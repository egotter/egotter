class DeviseCreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table(:users) do |t|
      t.bigint   :uid,              null: false
      t.string   :screen_name,      null: false
      t.boolean  :authorized,       null: false, default: true
      t.boolean  :locked,       null: false, default: false
      t.string   :token,            null: false
      t.string   :secret,           null: false
      t.string   :email,            null: false, default: ''
      t.datetime :first_sign_in_at, null: true
      t.datetime :last_sign_in_at,  null: true

      t.timestamps null: false

      t.index :uid, unique: true
      t.index :screen_name
      t.index :token
      t.index :created_at
    end
  end
end
