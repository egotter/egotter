namespace :twitter_db2 do
  namespace :users do
    desc 'copy from TwitterUser'
    task copy_from_twitter_users: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      start = ENV['START'] ? ENV['START'].to_i : 1
      batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 10
      process_start = Time.zone.now
      failed = false
      processed = 0
      puts "\ncopy started:"

      Rails.logger.silence do
        TwitterUser.find_in_batches(start: start, batch_size: batch_size) do |users_array|
          begin
            users = users_array.map { |user| TwitterDB2::User.new(uid: user.uid.to_i, screen_name: user.screen_name, user_info: user.user_info, friends_size: user.friends_size, followers_size: user.followers_size, created_at: user.created_at, updated_at: user.updated_at) }
            TwitterDB2::User.import(users, on_duplicate_key_update: %i(id), vaildate: false, timestamps: false)
            processed += users_array.size

            users_array.each do |user|
              users = user.friends.map { |friend| TwitterDB2::User.new(uid: friend.uid.to_i, screen_name: friend.screen_name, user_info: friend.user_info, friends_size: -1, followers_size: -1, created_at: user.created_at, updated_at: user.created_at) }
              users += user.followers.map { |follower| TwitterDB2::User.new(uid: follower.uid.to_i, screen_name: follower.screen_name, user_info: follower.user_info, friends_size: -1, followers_size: -1, created_at: user.created_at, updated_at: user.created_at) }
              users = users.uniq(&:uid)
              processed += users.size

              users.each_slice(1000) do |records|
                TwitterDB2::User.import(records, on_duplicate_key_update: %i(id), vaildate: false, timestamps: false)
              end
            end

          rescue => e
            puts "#{e.class} #{e.message.slice(0, 300)}"
            failed = true
          end

          avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
          puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{users_array[0].id} - #{users_array[-1].id}"

          break if sigint || failed
        end
      end

      process_finish = Time.zone.now
      puts "copy #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end

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
            TwitterDB2::User.import(users, on_duplicate_key_update: %i(uid screen_name user_info friends_size followers_size), vaildate: false, timestamps: false)
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
      invalid = []
      puts "\nverify started:"

      Rails.logger.silence do
        TwitterDB::User.find_in_batches(start: start, batch_size: batch_size) do |users|
          users2 = TwitterDB2::User.where(uid: users.map(&:uid)).to_a
          users.each do |user1|
            user2_index = users2.index { |user| user.uid == user1.uid }
            unless user2_index
              puts "invalid: #{user1.uid} doesn't exist"
              invalid << user1.uid
              next
            end

            user2 = users2.delete_at(user2_index)
            if %i(uid screen_name friends_size followers_size user_info).any? { |attr| user1[attr] != user2[attr] }
              puts "invalid: #{user1.uid} #{%i(uid screen_name friends_size followers_size user_info).select { |attr| user1[attr] != user2[attr] }.join(', ')}"
              invalid << user1.uid
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
      puts "invalid: #{invalid.inspect}" if invalid.any?
      puts "verify #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end
  end
end