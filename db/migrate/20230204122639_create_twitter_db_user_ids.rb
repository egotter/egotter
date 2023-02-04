class CreateTwitterDBUserIds < ActiveRecord::Migration[6.1]
  def change
    create_table :twitter_db_user_ids do |t|
      t.bigint :uid, null: false
      t.timestamps null: false

      t.index :uid, unique: true
    end
  end
end
