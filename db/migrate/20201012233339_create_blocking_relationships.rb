class CreateBlockingRelationships < ActiveRecord::Migration[6.0]
  def change
    create_table :blocking_relationships do |t|
      t.bigint :from_uid, null: false
      t.bigint :to_uid, null: false

      t.timestamp :created_at, null: false

      t.index [:from_uid, :to_uid], unique: true
      t.index [:to_uid, :from_uid], unique: true
    end
  end
end
