class CreateUserRetentionStats < ActiveRecord::Migration[4.2]
  def change
    create_table :user_retention_stats do |t|
      t.datetime :date,      null: false
      t.integer  :total,     null: false, default: 0

      (1..30).each { |n| t.integer "#{n}_days", null: false, default: 0 }
      (1..30).each { |n| t.integer "after_#{n}_days", null: false, default: 0 }

      t.timestamps null: false
    end

    add_index :user_retention_stats, :date, unique: true
  end
end
