namespace :logs do
  task delete: :environment do
    DeleteRecordsTask.new(ENV['TABLE'].constantize, ENV['YEAR'], ENV['MONTH']).start
  end
end
