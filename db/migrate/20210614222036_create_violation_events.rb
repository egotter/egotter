class CreateViolationEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :violation_events do |t|
      t.references :user

      t.string :name
      t.json :properties
      t.timestamp :time, null: false

      t.index [:name, :time]
      t.index :time
    end
  end
end
