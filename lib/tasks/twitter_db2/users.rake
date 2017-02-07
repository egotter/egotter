namespace :twitter_db2 do
  namespace :users do
    desc 'copy from TwitterDB::User to TwitterDB2::User'
    task copy: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start = ENV['START'] ? ENV['START'].to_i : 1
      batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
      process_start = Time.zone.now
      failed = false
      processed = 0
      puts "\ncopy started:"

      Rails.logger.silence do
        TwitterDB::User.find_in_batches(start: start, batch_size: batch_size) do |users|
          begin
            TwitterDB2::User.import(users, on_duplicate_key_update: %i(id), vaildate: false, timestamps: false)
          rescue => e
            puts "#{e.class} #{e.message.slice(0, 300)}"
            failed = true
          end

          processed += users.size
          avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
          puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{users[0].id} - #{users[-1].id}"

          break if sigint || failed
        end
      end

      process_finish = Time.zone.now
      puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end

    desc 'verify TwitterDB2::User'
    task verify: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start = ENV['START'] ? ENV['START'].to_i : 1
      batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
      process_start = Time.zone.now
      failed = false
      processed = 0
      puts "\nverify started:"

      Rails.logger.silence do
        TwitterDB::User.find_in_batches(start: start, batch_size: batch_size) do |users|
          users2 = TwitterDB2::User.where(uid: users.map(&:uid))
          users.each do |user1|
            user2 = users2.find { |user| user.uid == user1.uid }
            unless user2
              puts "invalid: #{user1.uid} doesn't exist"
              next
            end
            if %i(uid screen_name friends_size followers_size user_info).any? { |attr| user1[attr] != user2[attr] }
              puts "invalid: #{user1.uid} #{%i(uid screen_name friends_size followers_size user_info).select { |attr| user1[attr] != user2[attr] }.join(', ')}"
              next
            end
          end

          processed += users.size
          avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
          puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{users[0].id} - #{users[-1].id}"

          break if sigint || failed
        end
      end

      process_finish = Time.zone.now
      puts "verify #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end
  end
end