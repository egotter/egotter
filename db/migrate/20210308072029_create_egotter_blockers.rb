class CreateEgotterBlockers < ActiveRecord::Migration[6.0]
  def change
    create_table :egotter_blockers do |t|
      t.bigint :uid, null: false
      t.timestamp :created_at, null: false

      t.index :uid, unique: true
      t.index :created_at
    end
  end
end
