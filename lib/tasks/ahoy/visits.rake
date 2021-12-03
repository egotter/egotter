namespace :ahoy do
  namespace :visits do
    task delete: :environment do
      start_time = Time.zone.parse(ENV['SINCE'])
      end_time = Time.zone.parse(ENV['UNTIL'])
      begin
        DeleteAhoyRecordsTask.new(Ahoy::Visit, start_time, end_time).start
      rescue => e
        puts e.inspect
      end
    end
  end
end
