namespace :crawler_logs do
  desc 'Delete'
  task delete: :environment do
    CrawlerLog.delete_old_logs(ENV['YEAR'], ENV['MONTH'])
  end
end
