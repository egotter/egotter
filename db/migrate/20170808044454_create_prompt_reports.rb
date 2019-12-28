class CreatePromptReports < ActiveRecord::Migration[5.2]
  def change
    create_table :prompt_reports do |t|
      t.integer  :user_id,       null: false
      t.datetime :read_at,       null: true,  default: nil
      t.bigint   :removed_uid,   null: true, default: nil
      t.text     :changes_json,  null: false
      t.string   :token,         null: false
      t.string   :message_id,    null: false
      t.string   :message,       null: false, default: ''

      t.timestamps null: false

      t.index :user_id
      t.index :token, unique: true
      t.index :created_at
      t.index %i(user_id created_at)
    end
  end
end
