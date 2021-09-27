class CreateCheckoutSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :checkout_sessions do |t|
      t.bigint :user_id, null: false
      t.string :stripe_checkout_session_id, null: false
      t.json :properties

      t.timestamps

      t.index [:user_id, :stripe_checkout_session_id], name: 'index_on_user_id_and_scs_id', unique: true
      t.index :created_at
    end
  end
end
