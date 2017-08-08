class CreateSearchReports < ActiveRecord::Migration
  def change
    create_table :search_reports do |t|
      t.integer  :user_id,      null: false
      t.datetime :read_at,      null: true
      t.string   :message_id,   null: false
      t.string   :token,        null: false

      t.timestamps null: false
    end
    add_index :search_reports, :user_id
    add_index :search_reports, :token, unique: true
    add_index :search_reports, :created_at
  end
end
