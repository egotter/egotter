class CreateBackgroundUpdateLogs < ActiveRecord::Migration
  def change
    create_table :background_update_logs do |t|
      t.string :uid,     default: -1
      t.string :bot_uid, default: -1
      t.boolean :status, default: false
      t.string :reason,  default: ''

      t.timestamps null: false
    end
    add_index :background_update_logs, :uid
  end
end
