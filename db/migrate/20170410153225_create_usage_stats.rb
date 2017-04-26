class CreateUsageStats < ActiveRecord::Migration
  def change
    create_table :usage_stats, options: 'ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4' do |t|
      t.integer :uid, limit: 8,       null: false
      t.text    :wday_json,           null: false
      t.text    :wday_drilldown_json, null: false
      t.text    :hour_json,           null: false
      t.text    :hour_drilldown_json, null: false
      t.text    :usage_time_json,     null: false
      t.text    :breakdown_json,      null: false
      t.text    :hashtags_json,       null: false
      t.text    :mentions_json,       null: false
    end
    add_index :usage_stats, :uid, unique: true
  end
end
