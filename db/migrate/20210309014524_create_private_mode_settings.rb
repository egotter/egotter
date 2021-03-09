class CreatePrivateModeSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :private_mode_settings do |t|
      t.bigint :user_id, null: false

      t.timestamps null: false

      t.index :user_id, unique: true
      t.index :created_at
    end
  end
end
