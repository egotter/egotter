namespace :twitter_users do
  desc 'create'
  task create: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    specified_uids =
      if ENV['UIDS']
        ENV['UIDS'].remove(/ /).split(',').map(&:to_i)
      else
        uids = TwitterUser.uniq.pluck(:uid).map(&:to_i)
        User.authorized.pluck(:uid).map(&:to_i).reject { |uid| uids.include? uid }.take(500)
     end

    persisted_uids = TwitterUser.uniq.pluck(:uid).map(&:to_i)
    failed = false
    processed = []
    skipped = 0
    skipped_reasons = []

    specified_uids.each do |uid|
      if persisted_uids.include? uid
        skipped += 1
        skipped_reasons << "Persisted #{uid}"
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
          skipped_reasons << "Invalid token(user) #{uid}"
          next
        elsif ['Not authorized.', 'User not found.'].include? e.message
          skipped += 1
          skipped_reasons << "Not authorized or Not found #{uid}"
          next
        elsif e.message == 'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
          skipped += 1
          skipped_reasons << "Temporarily locked #{uid}"
          next
        end

        # Twitter::Error execution expired
        # Twitter::Error::InternalServerError Internal error

        puts "client.user: #{e.class} #{e.message} #{uid}"
        failed = true
        break
      end

      twitter_user = TwitterUser.build_by_user(t_user)
      twitter_user.user_id = user ? user.id : -1

      if t_user.suspended
        ActiveRecord::Base.transaction do
          twitter_user.update!(friends_size: 0, followers_size: 0)
          unless TwitterDB::User.exists?(uid: twitter_user.uid)
            TwitterDB::User.create!(uid: twitter_user.uid, screen_name: twitter_user.screen_name, user_info: twitter_user.user_info, friends_size: -1, followers_size: -1)
          end
        end
        puts "Create suspended #{uid}"
        next
      end

      if t_user.protected && client.verify_credentials.id != t_user.id
        friendship_uid = TwitterDB::Friendship.where(user_uid: User.authorized.pluck(:uid), friend_uid: uid).first&.user_uid
        if friendship_uid
          puts "Change a client to update #{uid} from #{client.verify_credentials.id} to #{friendship_uid}"
          client = User.find_by(uid: friendship_uid).api_client
        else
          ActiveRecord::Base.transaction do
            twitter_user.update!(friends_size: 0, followers_size: 0)
            unless TwitterDB::User.exists?(uid: twitter_user.uid)
              TwitterDB::User.create!(uid: twitter_user.uid, screen_name: twitter_user.screen_name, user_info: twitter_user.user_info, friends_size: -1, followers_size: -1)
            end
          end
          puts "Create protected #{uid}"
          next
        end
      end

      if twitter_user.too_many_friends?(login_user: user)
        ActiveRecord::Base.transaction do
          twitter_user.update!(friends_size: 0, followers_size: 0)
          unless TwitterDB::User.exists?(uid: twitter_user.uid)
            TwitterDB::User.create!(uid: twitter_user.uid, screen_name: twitter_user.screen_name, user_info: twitter_user.user_info, friends_size: -1, followers_size: -1)
          end
        end
        puts "Create too many friends #{uid}"
        next
      end

      begin
        signatures = [{method: :friend_ids,   args: [uid]}, {method: :follower_ids, args: [uid]}]
        friend_uids, follower_uids = client._fetch_parallelly(signatures)
      rescue => e
        if e.message == 'Invalid or expired token.'
          user&.update(authorized: false)
          skipped += 1
          skipped_reasons << "Invalid token(friend_ids) #{uid}"
          next
        end

        puts "client.friend_ids: #{e.class} #{e.message} #{uid}"
        failed = true
        break
      end

      if (t_user.friends_count - friend_uids.size).abs >= 5 || (t_user.followers_count - follower_uids.size).abs >= 5
        puts "Inconsistent #{uid} [#{t_user.friends_count}, #{friend_uids.size}] [#{t_user.followers_count}, #{follower_uids.size}]"
        failed = true
        break
      end

      begin
        ActiveRecord::Base.transaction do
          twitter_user.update!(friends_size: friend_uids.size, followers_size: follower_uids.size)
          Friendships.import(twitter_user.id, friend_uids, follower_uids)
        end
      rescue => e
        puts "Friendships.import: #{e.class} #{e.message.truncate(100)} #{uid}"
        failed = true
        break
      end

      begin
        Rails.logger.silence { TwitterDB::Users.fetch_and_import((friend_uids + follower_uids).uniq, client: client) }
      rescue => e
        puts "TwitterDB::Users.fetch_and_import: #{e.class} #{e.message.truncate(100)} #{uid}"
        failed = true
        break
      end

      begin
        ActiveRecord::Base.transaction do
          TwitterDB::User.find_or_initialize_by(uid: twitter_user.uid).update!(screen_name: twitter_user.screen_name, user_info: twitter_user.user_info, friends_size: friend_uids.size, followers_size: follower_uids.size)
          TwitterDB::Friendships.import(twitter_user.uid, friend_uids, follower_uids)
        end
      rescue => e
        puts "TwitterDB::Friendships.import: #{e.class} #{e.message.truncate(100)} #{uid}"
        failed = true
        break
      end

      processed << twitter_user

      break if sigint || failed
    end

    if processed.any?
      users = TwitterDB::User.where(uid: processed.take(500).map(&:uid)).index_by(&:uid)
      puts "\nprocessed:"
      puts processed.take(500).map { |tu|
        u = users[tu.uid.to_i]
        "  #{tu.uid} [#{tu.friends_size}, #{tu.friends_count}, #{u&.friends_size}, #{u&.friends_count}] [#{tu.followers_size}, #{tu.followers_count}, #{u&.followers_size}, #{u&.followers_count}]"
      }.join("\n")
    end

    if skipped_reasons.any?
      puts "\nskipped reasons:"
      puts skipped_reasons.take(500).map { |r| "  #{r}" }.join("\n")
    end

    puts "\ncreate #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  uids: #{specified_uids.size}, processed: #{processed.size}, skipped: #{skipped}"
  end
end
