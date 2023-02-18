namespace :twitter_db do
  namespace :user_ids do
    task consume_jobs: :environment do |task|
      limit = ENV['LIMIT']&.to_i || 100
      loop = ENV['LOOP']&.to_i || 300
      timeout = ENV['TIMEOUT']&.to_i || 100

      consumer = JobConsumer.new(ImportTwitterDBUserIdWorker, loop: loop, limit: limit, timeout: timeout)
      consumer.start

      puts "#{task.name}: #{consumer.format_progress}"
    end

    task import: :environment do |task|
      start = ENV['START']&.to_i || 1
      limit = ENV['LIMIT']&.to_i || 10000
      processed = 0
      last_id = nil
      sigint = Sigint.new.trap

      TwitterDB::User.select(:id, :uid).find_in_batches(start: start, batch_size: 1000) do |records|
        ImportTwitterDBUserIdWorker.new.perform(records.map(&:uid))
        print '.'

        processed += records.size
        last_id = records.last.id

        if processed >= limit
          puts "#{task.name}: limit reached"
          break
        end

        break if sigint.trapped?
      end

      puts "#{task.name}: processed #{processed}, last_id #{last_id}"
    end
  end
end
