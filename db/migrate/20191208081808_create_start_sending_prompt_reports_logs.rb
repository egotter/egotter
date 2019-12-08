class CreateStartSendingPromptReportsLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :start_sending_prompt_reports_logs do |t|
      t.json :properties
      t.datetime :started_at, null: true
      t.datetime :finished_at, null: true

      t.datetime :created_at, null: false

      t.index :created_at
    end
  end
end
