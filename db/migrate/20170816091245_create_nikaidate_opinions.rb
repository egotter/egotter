class CreateNikaidateOpinions < ActiveRecord::Migration
  def change
    create_table :nikaidate_opinions do |t|
      t.string  :uid,        null: false
      t.string  :status_id,  null: false
      t.text    :attrs_json, null: false

      t.timestamps null: false
    end
    add_index :nikaidate_opinions, :uid
    add_index :nikaidate_opinions, :status_id, unique: true
    add_index :nikaidate_opinions, :created_at
  end
end
