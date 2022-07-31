namespace :airbag do
  task consume_scheduled_jobs: :environment do |task|
    limit = ENV['LIMIT']&.to_i || 100
    loop = ENV['LOOP']&.to_i || 300
    timeout = ENV['TIMEOUT']&.to_i || 100

    consumer = JobConsumer.new(SendAirbagMessageToSlackWorker, limit: limit, loop: loop, timeout: timeout)
    consumer.start

    puts "#{task.name}: #{consumer.format_progress}"
  end
end
