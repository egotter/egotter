class CreateUnfollowers < ActiveRecord::Migration
  def change
    create_table :unfollowers, options: 'ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4' do |t|
      t.integer :uid,         null: false, limit: 8
      t.string  :screen_name, null: false
      t.text    :user_info,   null: false
      t.integer :from_id,     null: false, index: true

      t.datetime :created_at, null: false
    end
  end
end
