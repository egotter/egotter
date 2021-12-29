namespace :crawler_logs do
  task delete: :environment do
    DeleteLogsTask.new(CrawlerLog, ENV['YEAR'], ENV['MONTH']).start
  end
end
