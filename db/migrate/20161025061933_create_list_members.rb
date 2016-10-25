class CreateListMembers < ActiveRecord::Migration
  def change
    create_table :list_members, options: 'ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4' do |t|
      t.integer :list_id,     index: true,  null: false
      t.string  :uid,         unique: true, null: false
      t.string  :screen_name,               null: false
      t.text    :user_info,                 null: false

      t.datetime :created_at, null: false
    end
  end
end
