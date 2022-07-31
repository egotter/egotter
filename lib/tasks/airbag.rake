namespace :airbag do
  task consume_scheduled_jobs: :environment do
    limit = ENV['LIMIT']&.to_i || 100
    loop = ENV['LOOP']&.to_i || 300
    timeout = ENV['TIMEOUT']&.to_i || 100

    JobConsumer.new(SendAirbagMessageToSlackWorker, limit: limit, loop: loop, timeout: timeout).start
  end
end
