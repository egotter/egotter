class CreateGauges < ActiveRecord::Migration[5.2]
  def change
    create_table :gauges do |t|
      t.string   :name
      t.string   :label
      t.integer  :value
      t.datetime :time

      t.index :time
    end
  end
end
