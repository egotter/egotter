class DeviseCreateUsers < ActiveRecord::Migration
  def change
    create_table(:users) do |t|
      t.string  :uid,         null: false
      t.string  :screen_name, null: false
      t.boolean :authorized,  null: false, default: true
      t.string  :secret,      null: false
      t.string  :token,       null: false
      t.string  :email,       null: false, default: ''

      t.timestamps null: false
    end

    add_index :users, :uid, unique: true
    add_index :users, :screen_name
    add_index :users, :created_at
  end
end
