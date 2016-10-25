class CreateLists < ActiveRecord::Migration
  def change
    create_table :lists, id: false do |t|
      t.integer :id,  null: false
      t.string :name, null: false

      t.datetime :created_at, null: false
    end

    execute 'ALTER TABLE lists ADD PRIMARY KEY (id)'
  end
end
