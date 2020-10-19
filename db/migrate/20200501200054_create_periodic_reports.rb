class CreatePeriodicReports < ActiveRecord::Migration[5.2]
  def change
    create_table :periodic_reports do |t|
      t.integer  :user_id,       null: false
      t.datetime :read_at,       null: true,  default: nil
      t.string   :token,         null: false
      t.string   :message_id,    null: false
      t.string   :message,       null: false, default: ''
      t.json     :screen_names
      t.json     :properties

      t.timestamps null: false

      t.index :user_id
      t.index :token, unique: true
      t.index :created_at
      t.index %i(user_id created_at)
    end
  end
end
