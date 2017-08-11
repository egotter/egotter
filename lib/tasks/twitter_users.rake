namespace :twitter_users do
  desc 'create'
  task create: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    # uids = TwitterUser.pluck(:uid).uniq.map(&:to_i)
    # specified_uids = User.authorized.select(:uid).reject { |user| uids.include? user.uid.to_i }.map(&:uid).map(&:to_i)

    specified_uids = ENV['UIDS'].remove(/ /).split(',').map(&:to_i)
    persisted_uids = TwitterUser.pluck(:uid).map(&:to_i).uniq
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
        twitter_user = TwitterUser.build_by_user(t_user)
        twitter_user.user_id = user ? user.id : -1
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

        # Twitter::Error execution expired
        # Twitter::Error::InternalServerError Internal error

        puts "client.user: #{e.class} #{e.message} #{uid}"
        failed = true
        break
      end

      if t_user.protected && client.verify_credentials.id != t_user.id
        friendship_uid = TwitterDB::Friendship.where(user_uid: User.authorized.pluck(:uid), friend_uid: uid).first&.user_uid
        if friendship_uid
          puts "Change client #{uid} from #{client.verify_credentials.id} to #{friendship_uid}"
          client = User.find_by(uid: friendship_uid).api_client
        else
          skipped += 1
          skipped_reasons << "Protected #{uid}"
          next
        end
      end

      if twitter_user.too_many_friends?(login_user: user)
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
        TwitterDB::Users.fetch_and_import((friend_uids + follower_uids).uniq, client: client)
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
