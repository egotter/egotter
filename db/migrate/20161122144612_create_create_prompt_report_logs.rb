class CreateCreatePromptReportLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :create_prompt_report_logs do |t|
      t.integer  :user_id,     null: false, default: -1
      t.integer  :request_id,  null: false, default: -1
      t.string   :uid,         null: false, default: -1
      t.string   :screen_name, null: false, default: ''
      t.string   :bot_uid,     null: false, default: -1 # Drop
      t.boolean  :status,      null: false, default: false
      t.string   :reason,      null: false, default: '' # Drop
      t.text     :message,     null: false
      t.integer  :call_count,  null: false, default: -1 # Drop
      t.string   :error_class,   null: false, default: ''
      t.string   :error_message, null: false, default: ''

      t.datetime :created_at,  null: false

      t.index :uid
      t.index :screen_name
      t.index :created_at
    end
  end
end
