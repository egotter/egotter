namespace :friendships do
  desc 'refresh friendships and followerships'
  task refresh: :environment do
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
    puts "\nrefresh started:"

    Rails.logger.silence do
      TwitterUser.with_friends.find_in_batches(start: start, batch_size: batch_size) do |twitter_users|
        twitter_users.each do |twitter_user|
          begin
            ActiveRecord::Base.transaction do
              friend_uids = twitter_user.friends.pluck(:uid)
              follower_uids = twitter_user.followers.pluck(:uid)
              Friendship.import_from!(twitter_user.id, friend_uids)
              Followership.import_from!(twitter_user.id, follower_uids)

              twitter_user.update_columns(friends_size: friend_uids.size, followers_size: follower_uids.size)
            end
          rescue => e
            failed = true
            puts "#{twitter_user.id} #{twitter_user.uid} #{twitter_user.screen_name} #{e.class} #{e.message}"
          end

          break if sigint || failed
        end

        processed += twitter_users.size
        avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
        puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{twitter_users[0].id} - #{twitter_users[-1].id}"

        break if sigint || failed
      end
    end

    process_finish = Time.zone.now
    puts "refresh #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
  end

  desc 'verify friendships and followerships'
  task verify: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 100
    process_start = Time.zone.now
    puts "\nverify started:"

    processed = 0
    invalid = []
    Rails.logger.silence do
      TwitterUser.with_friends.find_in_batches(start: start, batch_size: batch_size) do |twitter_users_array|
        twitter_users_array.each do |twitter_user|
          friend_uids = [
            twitter_user.friends.pluck(:uid).map(&:to_i),
            twitter_user.friendships.pluck(:friend_uid)
          ]

          friends_size = [
            twitter_user.friends.size,
            twitter_user.friends_size,
            twitter_user.friendships.size,
            Friendship.where(from_id: twitter_user.id).size,
          ]

          follower_uids = [
            twitter_user.followers.pluck(:uid).map(&:to_i),
            twitter_user.followerships.pluck(:follower_uid)
          ]

          followers_size = [
            twitter_user.followers.size,
            twitter_user.followers_size,
            twitter_user.followerships.size,
            Followership.where(from_id: twitter_user.id).size,
          ]

          if [friend_uids, follower_uids, friends_size, followers_size].any? { |array| !array.combination(2).all? { |a, b| a == b } }
            invalid << twitter_user.id
            puts "invalid id: #{twitter_user.id}, uid: #{twitter_user.uid}, screen_name: #{twitter_user.screen_name}, friends: #{friends_size.inspect}, followers: #{followers_size.inspect}"
          end

          break if sigint
        end
        processed += twitter_users_array.size

        avg = '%4.1f' % (1000 * (Time.zone.now - process_start) / processed)
        puts "#{Time.zone.now}: processed #{processed}, avg(1000) #{avg}, #{twitter_users_array[0].id} - #{twitter_users_array[-1].id}"

        break if sigint
      end
    end

    process_finish = Time.zone.now
    puts "verify #{(sigint ? 'suspended:' : 'finished:')}"
    puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    puts "invalid #{invalid.inspect}" if invalid.any?
  end
end