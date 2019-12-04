class CreateAnnouncements < ActiveRecord::Migration[5.2]
  def change
    create_table :announcements do |t|
      t.boolean :status, null: false, default: true
      t.string :date, null: false
      t.string :message, null: false

      t.timestamps null: false

      t.index :created_at
    end
  end
end
