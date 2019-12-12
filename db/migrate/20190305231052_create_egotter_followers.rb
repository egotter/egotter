class CreateEgotterFollowers < ActiveRecord::Migration[5.1]
  def change
    create_table :egotter_followers do |t|
      t.string :screen_name, null: false
      t.bigint :uid,         null: false

      t.timestamps null: false

      t.index :uid, unique: true
      t.index :created_at
      t.index :updated_at
    end
  end
end
