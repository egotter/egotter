class CreateMentions < ActiveRecord::Migration
  def change
    create_table :mentions do |t|
      t.string :uid,         null: false
      t.string :screen_name, null: false
      t.text :status_info,   null: false
      t.integer :from_id,    null: false

      t.timestamps null: false
    end
    add_index :mentions, :uid
    add_index :mentions, :from_id
    add_index :mentions, :screen_name
    add_index :mentions, :created_at
  end
end
