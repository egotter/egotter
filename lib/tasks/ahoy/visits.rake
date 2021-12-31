namespace :ahoy do
  namespace :visits do
    task delete: :environment do
      DeleteRecordsTask.new(Ahoy::Visit, ENV['YEAR'], ENV['MONTH']).start
    end
  end
end
