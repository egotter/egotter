namespace :twitter_db do
  namespace :users do
    desc 'update TwitterDB::User'
    task update: :environment do
      sigint = false
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        sigint = true
      end

      # uids = TwitterDB::User.with_friends.pluck(:uid)
      # specified_uids = User.authorized.select(:uid).reject { |user| uids.include? user.uid.to_i }.map(&:uid).map(&:to_i)

      specified_uids = ENV['UIDS'].remove(/ /).split(',').map(&:to_i)
      with_friends_uids = TwitterDB::User.with_friends.pluck(:uid)
      failed = false
      processed = []
      skipped = 0
      skipped_reasons = []

      specified_uids.each do |uid|
        if with_friends_uids.include? uid
          skipped += 1
          skipped_reasons << "With friends #{uid}"
          next
        end

        user = User.authorized.find_by(uid: uid)
        client = user ? user.api_client : Bot.api_client

        begin
          t_user = client.user(uid)
        rescue => e
          if e.message == 'Invalid or expired token.'
            user&.update(authorized: false)
            skipped += 1
            skipped_reasons << "Invalid token #{uid}"
            next
          elsif ['Not authorized.', 'User not found.'].include? e.message
            skipped += 1
            skipped_reasons << "Not authorized or Not found #{uid}"
            next
          end

          puts "client.user: #{e.class} #{e.message} #{uid}"
          failed = true
          break
        end

        # TODO check protected

        if TwitterUser.build_by_user(t_user).too_many_friends?(login_user: user)
          skipped += 1
          skipped_reasons << "Too many friends #{uid}"
          next
        end

        begin
          signatures = [{method: :friend_ids,   args: [uid]}, {method: :follower_ids, args: [uid]}]
          friend_uids, follower_uids = client._fetch_parallelly(signatures)
        rescue => e
          puts "client.friend_ids: #{e.class} #{e.message} #{uid}"
          failed = true
          break
        end

        begin
          TwitterDB::Users.fetch_and_import((friend_uids + follower_uids).uniq, client: client)
        rescue => e
          puts "TwitterDB::Users.fetch_and_import: #{e.class} #{e.message.truncate(100)} #{uid}"
          failed = true
          break
        end

        begin
          ActiveRecord::Base.transaction do
            TwitterDB::User.find_or_initialize_by(uid: uid).update!(screen_name: t_user.screen_name, user_info: TwitterUser.collect_user_info(t_user), friends_size: friend_uids.size, followers_size: follower_uids.size)
            TwitterDB::Friendships.import(uid, friend_uids, follower_uids)
          end
        rescue => e
          puts "TwitterDB::Friendships.import: #{e.class} #{e.message.truncate(100)} #{uid}"
          failed = true
          break
        end

        processed << uid

        break if sigint || failed
      end

      if processed.any?
        users = TwitterDB::User.where(uid: processed.take(500)).index_by(&:uid)
        puts "\nprocessed:"
        puts processed.take(500).map { |uid|
          u = users[uid.to_i]
          "  #{uid} [#{u&.friends_size}, #{u&.friends_count}] [#{u&.followers_size}, #{u&.followers_count}]"
        }.join("\n")
      end

      if skipped_reasons.any?
        puts "\nskipped reasons:"
        puts skipped_reasons.take(500).map { |r| "  #{r}" }.join("\n")
      end

      puts "\nupdate #{(sigint || failed ? 'suspended:' : 'finished:')}"
      puts "  uids: #{specified_uids.size}, processed: #{processed.size}, skipped: #{skipped}"
    end
  end
end
