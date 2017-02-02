class CreateOldUsers < ActiveRecord::Migration
  def change
    create_table :old_users do |t|
      t.integer :uid,         null: false, limit: 8
      t.string  :screen_name, null: false
      t.boolean :authorized,  null: false, default: false
      t.string  :secret,      null: false
      t.string  :token,       null: false

      t.timestamps null: false
    end

    add_index :old_users, :uid, unique: true
    add_index :old_users, :screen_name
    add_index :old_users, :created_at
  end
end
