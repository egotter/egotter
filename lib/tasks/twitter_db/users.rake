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
            user.update!(screen_name: t_user.screen_name, user_info: t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json)
            next if user.protected_account?

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
            end

            user.update!(friends_size: user.friendships.size, followers_size: user.followerships.size)

          rescue => e
            puts "#{e.class} #{e.message.slice(0, 300)} #{user.uid} #{user.screen_name}"
            puts e.backtrace.join("\n")
            failed = true
          end

          processed += 1
          if processed % batch_size == 0
            avg = '%3.1f' % ((Time.zone.now - process_start) / processed)
            puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{user.id}"
          end

          break if sigint || failed
        end
      end

      process_finish = Time.zone.now
      puts "update #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  start: #{process_start}, finish: #{process_finish}, elapsed: #{(process_finish - process_start).round(1)} seconds"
    end
  end
end