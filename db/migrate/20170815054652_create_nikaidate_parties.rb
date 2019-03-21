class CreateNikaidateParties < ActiveRecord::Migration
  def change
    create_table :nikaidate_parties do |t|
      t.string  :uid,             null: false
      t.string  :screen_name,     null: false
      t.integer :citations_count, null: false, default: 0
      t.integer :rank,            null: false, default: 0
      t.text    :attrs_json,      null: false

      t.timestamps null: false
    end
    add_index :nikaidate_parties, :uid, unique: true
    add_index :nikaidate_parties, :citations_count
    add_index :nikaidate_parties, :rank
    add_index :nikaidate_parties, :created_at
  end
end
