class CreateStatuses < ActiveRecord::Migration
  def change
    create_table :statuses, options: 'ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4' do |t|
      t.string :uid,         null: false
      t.string :screen_name, null: false
      t.text :status_info,   null: false
      t.integer :from_id,    null: false

      t.timestamps null: false
    end
    add_index :statuses, :uid
    add_index :statuses, :from_id
    add_index :statuses, :screen_name
    add_index :statuses, :created_at
  end
end
