namespace :search_logs do
  task delete: :environment do
    DeleteRecordsTask.new(SearchLog, ENV['YEAR'], ENV['MONTH']).start
  end
end
