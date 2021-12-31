namespace :crawler_logs do
  task delete: :environment do
    DeleteRecordsTask.new(CrawlerLog, ENV['YEAR'], ENV['MONTH']).start
  end
end
