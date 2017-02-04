namespace :twitter_db do
  namespace :friendships do
    desc 'refresh friendships and followerships'
    task refresh: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
      process_start = Time.zone.now
      failed = false
      processed = 0
      puts "\nrefresh started:"

      Rails.logger.silence do
        TwitterUser.pluck(:uid).uniq.each_slice(batch_size) do |uids|
          TwitterDB::User.where(uid: uids.map(&:to_i)).each do |user|
            twitter_user = TwitterUser.latest(user.uid)

            begin
              ActiveRecord::Base.transaction do
                friend_uids = twitter_user.friendships.pluck(:friend_uid)
                if user.friendships.pluck(:friend_uid) != friend_uids
                  TwitterDB::Friendship.import_from!(user.uid, friend_uids)
                end

                follower_uids = twitter_user.followerships.pluck(:follower_uid)
                if user.followerships.pluck(:follower_uid) != follower_uids
                  TwitterDB::Followership.import_from!(user.uid, follower_uids)
                end

                user.update_columns(friends_size: friend_uids.size, followers_size: follower_uids.size)
              end
            rescue => e
              failed = true
              puts "#{user.id} #{user.uid} #{user.screen_name} #{e.class} #{e.message}"
            end

            break if sigint || failed
          end

          processed += uids.size
          avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
          puts "#{Time.zone.now}: processed #{processed}, avg #{avg}"

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

      batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 1000
      process_start = Time.zone.now
      puts "\nverify started:"

      processed = 0
      invalid = []
      Rails.logger.silence do
        TwitterUser.pluck(:uid).uniq.each_slice(batch_size) do |uids|
          TwitterDB::User.where(uid: uids.map(&:to_i)).each do |user|
            twitter_user = TwitterUser.latest(user.uid)

            friend_uids = [
              twitter_user.friendships.pluck(:friend_uid),
              user.friendships.pluck(:friend_uid)
            ]

            friends_size = [
              twitter_user.friendships.size,
              user.friends_size,
              user.friendships.size,
              TwitterDB::Friendship.where(user_uid: user.uid).size
            ]

            follower_uids = [
              twitter_user.followerships.pluck(:follower_uid),
              user.followerships.pluck(:follower_uid)
            ]

            followers_size = [
              twitter_user.followerships.size,
              user.followers_size,
              user.followerships.size,
              TwitterDB::Followership.where(user_uid: user.uid).size
            ]

            if [friend_uids, follower_uids, friends_size, followers_size].any? { |array| !array.combination(2).all? { |a, b| a == b } }
              invalid << user.id
              puts "invalid id: #{user.id}, uid: #{user.uid}, screen_name: #{user.screen_name}, friends: #{friends_size.inspect}, followers: #{followers_size.inspect}"
            end

            break if sigint
          end
          processed += uids.size

          avg = '%4.1f' % ((Time.zone.now - process_start) / processed)
          puts "#{Time.zone.now}: processed #{processed}, avg #{avg}"

          break if sigint
        end
      end

      process_finish = Time.zone.now
      puts "verify #{(sigint ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
      puts "invalid #{invalid.inspect}" if invalid.any?
    end
  end
end