class CreateVisitorEngagementStats < ActiveRecord::Migration
  def change
    create_table :visitor_engagement_stats do |t|
      t.datetime :date,  null: false
      t.integer  :total, null: false, default: 0

      (1..30).each do |n|
        t.integer "#{n}_days", null: false, default: 0
      end

      t.timestamps null: false
    end

    add_index :visitor_engagement_stats, :date, unique: true
  end
end
