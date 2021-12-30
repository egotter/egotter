namespace :ahoy do
  namespace :visits do
    task delete: :environment do
      DeleteAhoyRecordsTask.new(Ahoy::Visit, ENV['YEAR'], ENV['MONTH']).start
    end
  end
end
