namespace :search_logs do
  task delete: :environment do
    DeleteLogsTask.new(SearchLog, ENV['YEAR'], ENV['MONTH']).start
  end
end
