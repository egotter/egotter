class CreateCacheDirectories < ActiveRecord::Migration[5.2]
  def change
    create_table :cache_directories do |t|
      t.string :name, null: false
      t.string :dir, null: false

      t.timestamps null: false

      t.index :name, unique: true
      t.index :dir, unique: true
    end
  end
end
