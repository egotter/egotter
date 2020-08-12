class CreateGlobalMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :global_messages do |t|
      t.text :text, null: false
      t.datetime :expires_at

      t.timestamps null: false

      t.index :expires_at
      t.index :created_at
    end
  end
end
