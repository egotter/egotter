class DeviseCreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table(:users) do |t|
      t.integer  :uid,              null: false, limit: 8
      t.string   :screen_name,      null: false
      t.boolean  :authorized,       null: false, default: true
      t.string   :secret,           null: false
      t.string   :token,            null: false
      t.string   :email,            null: false, default: ''
      t.datetime :first_access_at,  null: true
      t.datetime :last_access_at,   null: true
      t.datetime :first_search_at,  null: true
      t.datetime :last_search_at,   null: true
      t.datetime :first_sign_in_at, null: true
      t.datetime :last_sign_in_at,  null: true

      t.timestamps null: false
    end

    add_index :users, :uid, unique: true
    add_index :users, :screen_name
    add_index :users, :created_at
  end
end
