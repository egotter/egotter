class CreateBackgroundUpdateLogs < ActiveRecord::Migration
  def change
    create_table :background_update_logs do |t|
      t.text :uid
      t.boolean :status
      t.text :reason

      t.timestamps null: false
    end
    add_index :background_update_logs, :uid
  end
end
