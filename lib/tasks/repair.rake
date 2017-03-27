namespace :repair do
  desc 'check'
  task check: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    last = ENV['LAST'] ? ENV['LAST'].to_i : TwitterUser.maximum(:id)
    verbose = ENV['VERBOSE'].present?
    not_found = []
    friendless = []
    not_consistent = []
    processed = 0
    start_time = Time.zone.now
    puts "\ncheck started:"

    Rails.logger.silence do
      TwitterUser.where('id <= ?', last).find_in_batches(start: start, batch_size: 1000) do |twitter_users|

        twitter_users.each do |tu|
          user = TwitterDB::User.find_by(uid: tu.uid)

          if user
            if verbose
              if user.friends_size == -1 || user.followers_size == -1
                puts "friendless #{tu.id} #{tu.uid}"
                friendless << tu.id
              end
            end
          else
            puts "not found #{tu.id} #{tu.uid}"
            not_found << tu.id
          end

          friends = [
            tu.friendships.size,
            tu.friends_size,
            verbose ? tu.friends.size : nil,
            verbose ? tu.friends_count : nil
          ].compact

          followers = [
            tu.followerships.size,
            tu.followers_size,
            verbose ? tu.followers.size : nil,
            verbose ? tu.followers_count : nil
          ].compact

          if friends.uniq.many? || followers.uniq.many?
            puts "not consistent #{tu.id} #{tu.uid} #{friends.inspect} #{followers.inspect}"
            not_consistent << tu.id
          end

          break if sigint
        end

        processed += twitter_users.size
        avg = '%3.1f' % ((Time.zone.now - start_time) / processed)
        puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{twitter_users[0].id} - #{twitter_users[-1].id}"

        break if sigint
      end
    end

    puts "TwitterDB::User not_found #{not_found.inspect.remove(' ')}" if not_found.any?
    puts "TwitterDB::User friendless #{friendless.inspect.remove(' ')}" if friendless.any?
    puts "TwitterUser not_consistent #{not_consistent.inspect.remove(' ')}" if not_consistent.any?
    puts "check #{(sigint ? 'suspended:' : 'finished:')}"
    puts "  start: #{start}, last: #{last}, processed: #{processed}, not_found: #{not_found.size}, friendless: #{friendless.size}, not_consistent: #{not_consistent.size}, started_at: #{start_time}, finished_at: #{Time.zone.now}"
  end

  namespace :fix do
    desc 'not_found'
    task not_found: :environment do
      ids = ENV['IDS'].remove(/ /).split(',')
      uids = TwitterUser.where(id: ids).pluck(:uid).map(&:to_i).uniq

      begin
        t_users = Bot.api_client.users(uids)
      rescue => e
        puts "#{e.class} #{e.message} uids: #{uids.size}"
        if e.message == 'No user matches for specified terms.'
          t_users =  []
        else
          raise
        end
      end

      import_users = t_users.map { |t_user| TwitterDB::User.to_import_format(t_user) }
      remaining = uids - t_users.map(&:id)

      remaining.each do |uid|
        TwitterUser.latest(uid).tap { |tu| import_users << [uid, tu.screen_name, tu.user_info, -1, -1] }
      end

      TwitterDB::User.import_each_slice(import_users)
      import_users.each { |user| puts "imported #{user.id}" }
      puts

      puts "ids: #{ids.size}, uids: #{uids.size}, t_users: #{t_users.size}, import_users: #{import_users.size} remaining: #{remaining.size}"
    end

    desc 'friendless'
    task friendless: :environment do
      ids = ENV['IDS'].remove(/ /).split(',')
      uids = TwitterUser.where(id: ids).pluck(:uid).map(&:to_i).uniq
      saved = []

      uids.each do |uid|
        user = TwitterDB::User.find_by(uid: uid)
        unless user
          puts "skipped because not found #{uid}"
          next
        end

        tu = TwitterUser.latest(uid)
        if tu.friends_count + tu.followers_count > TwitterUser::TOO_MANY_FRIENDS
          puts "skipped because too many friends #{tu.uid}"
          next
        end

        client = ApiClient.better_client(uid)
        user = TwitterDB::User.builder(uid).client(client).build
        user.persist!
        user = TwitterDB::User.find_by(uid: uid)

        puts "saved #{user.uid} #{[user.friendships.size, user.friends.size].inspect} #{[user.followerships.size, user.followers.size].inspect}"
        saved << uid

        sleep 3
      end

      puts "ids: #{ids.size}, uids: #{uids.size} saved: #{saved.size}"
    end

    desc 'not_consistent'
    task not_consistent: :environment do
      ids = ENV['IDS'].remove(/ /).split(',').map(&:to_i)

      ids.each do |twitter_user_id|
        twitter_user = TwitterUser.find(twitter_user_id)
        uid = twitter_user.uid.to_i

        clients = [
          User.authorized.find_by(uid: uid)&.api_client,
          User.authorized.find_by(id: twitter_user.user_id)&.api_client,
          Bot.api_client
        ]

        ex = nil
        t_user = friend_uids = follower_uids = nil
        not_found = unauthorized = success = false

        clients.each.with_index do |client, i|
          next unless client

          begin
            t_user = client.user(uid)
            friend_uids = client.friend_ids(uid)
            follower_uids = client.follower_ids(uid)
            success = true
          rescue Twitter::Error::Unauthorized => e
            if e.message == 'Invalid or expired token.' && i != clients.size - 1
              User.find_by(token: client.access_token, secret: client.access_token_secret).update(authorized: false)
            elsif e.message == 'Not authorized.'
              unauthorized = i == clients.size - 1
            else
              ex = e
            end
          rescue Twitter::Error::Forbidden => e
            if e.message == 'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
              # TODO
            else
              ex = e
            end
          rescue Twitter::Error::NotFound => e
            if e.message == 'User not found.'
              not_found = true
            else
              ex = e
            end
          rescue Twitter::Error::TooManyRequests => e
            puts "reset in #{e.rate_limit.reset_in} seconds"
            ex = e
          rescue => e
            ex = e
          end

          break if ex || not_found || success
        end

        if ex
          puts "Failed #{ex.class} #{ex.message} #{twitter_user_id} #{uid}"
          puts ex.backtrace.grep_v(/\.bundle/).join "\n"
          break
        end

        if not_found || unauthorized
          ActiveRecord::Base.transaction do
            twitter_user.update!(friends_size: 0, followers_size: 0)
            Friendship.import_from!(twitter_user.id, [])
            Followership.import_from!(twitter_user.id, [])
          end

          ActiveRecord::Base.transaction do
            Unfriendship.import_from!(uid, TwitterUser.calc_removing_uids(uid))
            Unfollowership.import_from!(uid, TwitterUser.calc_removed_uids(uid))
          end

          TwitterUser.find(twitter_user_id).tap do |tu|
            puts "Complete(#{not_found ? 'not found' : 'unauthorized'}) #{tu.protected_account?} #{tu.one?} #{tu.latest?} #{tu.size} #{tu.id} #{tu.uid} #{[tu.friendships.size, tu.friends_size, tu.followerships.size, tu.followers_size].inspect}"
          end

          next
        end

        if success
          latest = twitter_user.latest?
          if latest
            ActiveRecord::Base.transaction do
              twitter_user.update!(user_info: t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, friends_size: friend_uids.size, followers_size: follower_uids.size)
              Friendship.import_from!(twitter_user.id, friend_uids)
              Followership.import_from!(twitter_user.id, follower_uids)
            end

            twitter_user = TwitterUser.find(twitter_user_id)

            OneSidedFriendship.import_from!(uid, twitter_user.calc_one_sided_friend_uids)
            OneSidedFollowership.import_from!(uid, twitter_user.calc_one_sided_follower_uids)
            MutualFriendship.import_from!(uid, twitter_user.calc_mutual_friend_uids)
          else
            ActiveRecord::Base.transaction do
              twitter_user.update!(friends_size: 0, followers_size: 0)
              Friendship.import_from!(twitter_user.id, [])
              Followership.import_from!(twitter_user.id, [])
            end
          end

          ActiveRecord::Base.transaction do
            Unfriendship.import_from!(uid, TwitterUser.calc_removing_uids(uid))
            Unfollowership.import_from!(uid, TwitterUser.calc_removed_uids(uid))
          end

          TwitterUser.find(twitter_user_id).tap do |tu|
            puts "Complete #{tu.protected_account?} #{tu.one?} #{latest} #{tu.size} #{tu.id} #{tu.uid} #{[tu.friendships.size, tu.friends_size, tu.followerships.size, tu.followers_size].inspect}"
          end

          next
        end

        raise "something wrong #{twitter_user_id} #{uid}"
      end
    end
  end
end