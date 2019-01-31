class CreateFollowerships < ActiveRecord::Migration[4.2]
  def change
    create_table :followerships, id: false do |t|
      t.column  :id,          'BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT'
      t.integer :from_id,                index: true, null: false
      t.integer :follower_uid, limit: 8, index: true, null: false
      t.integer :sequence,                            null: false
    end
    add_index :followerships, %i(from_id follower_uid), unique: true
  end
end
