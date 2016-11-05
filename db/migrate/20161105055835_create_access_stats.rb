class CreateAccessStats < ActiveRecord::Migration
  def change
    create_table :access_stats do |t|
      t.datetime :date,      null: false
      t.integer  :'0_days',  null: false, default: 0
      t.integer  :'1_days',  null: false, default: 0
      t.integer  :'3_days',  null: false, default: 0
      t.integer  :'7_days',  null: false, default: 0
      t.integer  :'14_days', null: false, default: 0
      t.integer  :'30_days', null: false, default: 0

      t.timestamps null: false
    end

    add_index :access_stats, :date, unique: true
  end
end
