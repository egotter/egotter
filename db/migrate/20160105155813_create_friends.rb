class CreateFriends < ActiveRecord::Migration[4.2]
  def change
    create_table :friends, options: 'ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4' do |t|
      t.string :uid,         null: false
      t.string :screen_name, null: false
      t.text :user_info,     null: false
      t.integer :from_id,    null: false, index: true

      t.datetime :created_at, null: false
    end
  end
end
