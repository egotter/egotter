class CreateBots < ActiveRecord::Migration[4.2]
  def change
    create_table :bots do |t|
      t.bigint  :uid,         null: false
      t.string  :screen_name, null: false
      t.boolean :authorized,  null: false, default: true
      t.string  :secret,      null: false
      t.string  :token,       null: false

      t.timestamps null: false

      t.index :uid, unique: true
      t.index :screen_name
    end
  end
end
