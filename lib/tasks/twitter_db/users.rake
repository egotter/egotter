namespace :twitter_db do
  namespace :users do
    task consume_jobs: :environment do |task|
      limit = ENV['LIMIT']&.to_i || 100
      loop = ENV['LOOP']&.to_i || 300
      timeout = ENV['TIMEOUT']&.to_i || 100

      consumer = JobConsumer.new(ImportTwitterDBUserWorker, loop: loop, limit: limit, timeout: timeout)
      consumer.start

      puts "#{Time.zone.now.to_s(:db)} task=#{task.name} #{consumer.format_progress}"
    end
  end
end
