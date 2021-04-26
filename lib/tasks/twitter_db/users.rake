namespace :twitter_db do
  namespace :users do
    desc 'create TwitterDB::User'
    task create: :environment do
      uids = ENV['UIDS'].remove(' ').split(',').map(&:to_i)
      CreateTwitterDBUserWorker.perform_async(uids, enqueued_by: 'twitter_db:users:create')
    end

    task search: :environment do
      word = ENV['WORD']
      raise if word.blank?

      start_id = ENV['START_ID']&.to_i || 1
      limit = ENV['LIMIT']&.to_i || 100
      output = ENV['OUTPUT'] || 'output.txt'

      loop_count = 0
      result_count = 0
      uids = []
      last_id = nil
      start_time = Time.zone.now

      flush_result = lambda do
        File.open(output, 'a') { |f| f.puts uids.join("\n") }
        uids.clear
        puts "#{Time.zone.now.to_s(:db)} loop_count #{loop_count}, result_count #{result_count}, last_id #{last_id}, elapsed #{sprintf("%.3f sec", Time.zone.now - start_time)}"
      end

      process_user = lambda do |user|
        uids << user.uid
        last_id = user.id
        result_count += 1

        if uids.size >= 1000
          flush_result.call
        end
      end

      TwitterDB::User.where('description regexp ?', word).find_in_batches(start: start_id, batch_size: 1000) do |users|
        loop_count += 1

        users.each do |user|
          process_user.call(user)
          break if result_count >= limit
        end

        if result_count >= limit
          puts 'limit reached'
          break
        end
      end

      if uids.any?
        flush_result.call
      end
    end
  end
end
