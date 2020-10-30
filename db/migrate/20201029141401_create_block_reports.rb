class CreateBlockReports < ActiveRecord::Migration[6.0]
  def change
    create_table :block_reports do |t|
      t.integer  :user_id,    null: false
      t.string   :message_id, null: false, default: ''
      t.string   :message,    null: false, default: ''
      t.string   :token,      null: false
      t.datetime :read_at,    null: true

      t.timestamps null: false

      t.index :user_id
      t.index :token, unique: true
      t.index :created_at
    end
  end
end
