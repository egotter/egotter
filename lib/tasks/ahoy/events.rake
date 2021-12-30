namespace :ahoy do
  namespace :events do
    task delete: :environment do
      DeleteAhoyRecordsTask.new(Ahoy::Event, ENV['YEAR'], ENV['MONTH']).start
    end
  end
end
