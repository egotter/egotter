namespace :twitter_db do
  namespace :users do
    task consume_scheduled_jobs: :environment do
      limit = ENV['LIMIT']&.to_i || 100
      count = ENV['COUNT']&.to_i || 1
      timeout = ENV['TIMEOUT']&.to_i || 10
      start = Time.zone.now

      count.times do
        ImportTwitterDBUserWorker.consume_scheduled_jobs(limit: limit)

        if Time.zone.now - start > timeout
          puts 'Timeout'
          break
        end

        sleep 0.5
      end
    end
  end
end
