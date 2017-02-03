class CreateBots < ActiveRecord::Migration
  def change
    create_table :bots do |t|
      t.integer :uid,         null: false, limit: 8
      t.string  :screen_name, null: false, index: true
      t.string  :secret,      null: false
      t.string  :token,       null: false

      t.timestamps null: false
    end

    add_index :bots, :uid, unique: true
  end
end
