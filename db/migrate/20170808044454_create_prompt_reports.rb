class CreatePromptReports < ActiveRecord::Migration
  def change
    create_table :prompt_reports do |t|
      t.integer  :user_id,      null: false
      t.datetime :read_at,      null: true
      t.text     :changes_json, null: false
      t.string   :message_id,   null: false
      t.string   :token,        null: false

      t.timestamps null: false
    end
    add_index :prompt_reports, :user_id
    add_index :prompt_reports, :token, unique: true
    add_index :prompt_reports, :created_at
  end
end
