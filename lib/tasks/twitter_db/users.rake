namespace :twitter_db do
  namespace :users do
    desc 'update TwitterDB::User'
    task update: :environment do
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
      puts "\nupdate started:"

      Rails.logger.silence do
        TwitterDB::User.where(friends_size: -1, followers_size: -1).find_each(start: start, batch_size: batch_size) do |user|
          client = User.exists?(uid: user.uid) ? User.find_by(uid: user.uid).api_client : Bot.api_client
          begin
            t_user = client.user(user.uid)
            if t_user.protected_account?
              # puts "skip(protected) [#{user.id}, #{t_user.screen_name}, #{t_user.friends_count}, #{t_user.followers_count}]"
              user.update!(screen_name: t_user.screen_name, user_info: t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json)
              next
            end
            if (t_user.friends_count + t_user.followers_count) > 5000
              # puts "skip(too many friends) [#{user.id}, #{t_user.screen_name}, #{t_user.friends_count}, #{t_user.followers_count}]"
              user.update!(screen_name: t_user.screen_name, user_info: t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json)
              next
            end

            friends = client.friends(user.uid)
            followers = client.followers(user.uid)

            users =
              (friends + followers).map do |user|
                TwitterDB::User.new(uid: user.id, screen_name: user.screen_name, user_info: user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, friends_size: -1, followers_size: -1)
              end

            users.uniq(&:uid).each_slice(1000) do |array|
              TwitterDB::User.import(array, on_duplicate_key_update: %i(uid screen_name user_info), validate: false)
            end

            ActiveRecord::Base.transaction do
              TwitterDB::Friendship.import_from!(user.uid, friends.map(&:id))
              TwitterDB::Followership.import_from!(user.uid, followers.map(&:id))
              user.update!(screen_name: t_user.screen_name, user_info: t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, friends_size: friends.size, followers_size: followers.size)
            end

            processed += (1 + friends.size + followers.size)

          rescue Twitter::Error::TooManyRequests => e
            puts "#{e.message} limit #{e.rate_limit.limit} reset in #{e.rate_limit.reset_in} #{user.uid} #{user.screen_name}"
            failed = true
          rescue Twitter::Error::Unauthorized => e
            if e.message == 'Not authorized.'
              puts "#{e.class} #{e.message} #{user.uid} #{user.screen_name}"
            else
              failed = true
            end
          rescue => e
            puts "#{e.class} #{e.message.slice(0, 300)} #{user.uid} #{user.screen_name}"
            puts e.backtrace.join("\n")
            failed = true
          end

          if sigint || failed
            break
          else
            avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
            puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, [#{user.id}, #{user.screen_name}, #{user.friends_count}, #{user.followers_count}]"
          end
        end
      end

      process_finish = Time.zone.now
      puts "update #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, processed: #{processed}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end
  end
end
