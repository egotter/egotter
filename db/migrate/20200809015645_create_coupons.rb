class CreateCoupons < ActiveRecord::Migration[5.2]
  def change
    create_table :coupons do |t|
      t.integer :user_id, null: false
      t.integer :search_count, null: false
      t.string :stripe_coupon_id, null: true
      t.datetime :expires_at, null: false

      t.timestamps null: false

      t.index :user_id
      t.index :created_at
    end
  end
end
