namespace :twitter_users do
  desc 'create'
  task create: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    specified_uids = ENV['UIDS'].remove(/ /).split(',').map(&:to_i)
    persisted_uids = TwitterUser.pluck(:uid).map(&:to_i).uniq
    failed = false
    processed = skipped = 0

    specified_uids.each do |uid|
      if persisted_uids.include? uid
        skipped += 1
        next
      end

      user = User.find_by(uid: uid, authorized: true)
      client = user ? user.api_client : Bot.api_client
      twitter_user = nil

      begin
        t_user = client.user(uid)
        twitter_user = TwitterUser.build_by_user(t_user)
        twitter_user.user_id = user ? user.id : -1
      rescue => e
        if e.message == 'Invalid or expired token.'
          user.update(authorized: false)
        elsif ['Not authorized.', 'User not found.'].include? e.message
          skipped += 1
          next
        end

        puts "client.user: #{e.class} #{e.message} #{uid}"
        failed = true
        break
      end

      if twitter_user.too_many_friends?(login_user: user)
        skipped += 1
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
        t_users = client.users((friend_uids + follower_uids).uniq)
        TwitterDB::Users.import(t_users)
      rescue => e
        puts "TwitterDB::Users.import: #{e.class} #{e.message.truncate(100)} #{uid}"
        failed = true
        break
      end

      if t_users.size != (friend_uids + follower_uids).uniq.size
        suspended_uids = (friend_uids + follower_uids).uniq - t_users.map(&:id)
        suspended_uids -= TwitterDB::User.where(uid: suspended_uids).pluck(:uid)
        suspended_t_users =  suspended_uids.map { |id| Hashie::Mash.new(id: id, screen_name: 'suspended', description: '') }
        TwitterDB::Users.import(suspended_t_users)
        puts "#{uid} suspended #{suspended_uids.inspect}"
      end

      begin
        ActiveRecord::Base.transaction do
          user = TwitterDB::User.find_or_initialize_by(uid: twitter_user.uid)
          user.assign_attributes(screen_name: twitter_user.screen_name, user_info: twitter_user.user_info, friends_size: friend_uids.size, followers_size: follower_uids.size)
          user.save!

          TwitterDB::Friendships.import(twitter_user.uid, friend_uids, follower_uids)
        end
      rescue => e
        puts "TwitterDB::Friendships.import: #{e.class} #{e.message.truncate(100)} #{uid}"
        failed = true
        break
      end

      processed += 1

      break if sigint || failed
    end

    puts "create #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  uids: #{specified_uids.size}, processed: #{processed}, skipped: #{skipped}"
  end
end
