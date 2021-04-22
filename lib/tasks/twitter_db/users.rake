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

      count = 0
      uids = []
      start_time = Time.zone.now

      TwitterDB::User.where('description regexp ?', word).find_each(start: start_id, batch_size: 1000) do |user|
        uids << user.uid
        count += 1

        if uids.size >= 1000
          File.open(output, 'a') { |f| f.puts uids.join("\n") }
          uids.clear
          puts "count #{count}, elapsed #{sprintf("%.3f sec", Time.zone.now - start_time)}"
        end

        if count >= limit
          puts 'limit reached'
          break
        end
      end

      if uids.any?
        File.open(output, 'a') { |f| f.puts uids.join("\n") }
        puts "count #{count}, elapsed #{sprintf("%.3f sec", Time.zone.now - start_time)}"
      end
    end
  end
end
