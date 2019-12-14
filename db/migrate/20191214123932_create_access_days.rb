class CreateAccessDays < ActiveRecord::Migration[5.2]
  def change
    create_table :access_days do |t|
      t.integer :user_id, null: false
      t.string :date, null: false

      t.timestamps null: false

      t.index %i(user_id date), unique: true
    end
  end
end
