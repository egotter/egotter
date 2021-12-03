namespace :ahoy do
  namespace :events do
    task delete: :environment do
      start_time = Time.zone.parse(ENV['SINCE'])
      end_time = Time.zone.parse(ENV['UNTIL'])
      loop_count = ENV['LOOP']&.to_i
      time_range = ENV['RANGE']&.to_i

      begin
        DeleteAhoyRecordsTask.new(Ahoy::Event, start_time, end_time, loop_count: loop_count, time_range: time_range).start
      rescue => e
        puts e.inspect
      end
    end
  end
end
