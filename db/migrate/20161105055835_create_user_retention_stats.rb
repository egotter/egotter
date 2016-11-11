class CreateUserRetentionStats < ActiveRecord::Migration
  def change
    create_table :user_retention_stats do |t|
      t.datetime :date,      null: false
      t.integer  :total,     null: false, default: 0
      t.integer  :'1_days',  null: false, default: 0
      t.integer  :'2_days',  null: false, default: 0
      t.integer  :'3_days',  null: false, default: 0
      t.integer  :'4_days',  null: false, default: 0
      t.integer  :'5_days',  null: false, default: 0
      t.integer  :'6_days',  null: false, default: 0
      t.integer  :'7_days',  null: false, default: 0
      t.integer  :'14_days', null: false, default: 0
      t.integer  :'30_days', null: false, default: 0

      t.timestamps null: false
    end

    add_index :user_retention_stats, :date, unique: true
  end
end
