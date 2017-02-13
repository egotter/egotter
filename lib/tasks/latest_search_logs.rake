namespace :latest_search_logs do
  desc 'update'
  task update: :environment do
    ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS latest_search_logs')
    ActiveRecord::Base.connection.execute('CREATE TABLE latest_search_logs like search_logs')
    start_time = 40.days.ago.beginning_of_day.to_s(:db)
    end_time = Time.zone.now.end_of_day.to_s(:db)
    ActiveRecord::Base.connection.execute("insert into latest_search_logs select * from search_logs where created_at BETWEEN '#{start_time}' AND '#{end_time}'")
  end
end
