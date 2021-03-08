class CreateEgotterFollowers < ActiveRecord::Migration[5.1]
  def change
    create_table :egotter_followers do |t|
      t.string :screen_name, null: true
      t.bigint :uid,         null: false

      t.timestamps null: false

      t.index :uid, unique: true
      t.index :created_at
    end
  end
end
