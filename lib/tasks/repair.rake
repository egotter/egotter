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
    not_found = []
    not_consistent = []
    processed = 0
    start_time = Time.zone.now
    failed = false
    puts "\nrepair started:"

    Rails.logger.silence do
      TwitterUser.find_in_batches(start: start, batch_size: 1000) do |twitter_users|
        break if twitter_users[0].id > last

        twitter_users.each do |tu|
          break if tu.id > last

          user = TwitterDB::User.find_by(uid: tu.uid)
          unless user
            puts "TwitterDB::user is not found #{tu.id} #{tu.uid}"
            not_found << tu.id
            next
          end

          friends = [
            # tu.friends.size,
            tu.friendships.size,
            tu.friends_size,
            # tu.friends_count,
            # user.friends.size,
            # user.friendships.size,
            # user.friends_size,
            # user.friends_count
          ]

          followers = [
            # tu.followers.size,
            tu.followerships.size,
            tu.followers_size,
            # tu.followers_count,
            # user.followers.size,
            # user.followerships.size,
            # user.followers_size,
            # user.followers_count
          ]

          if friends.uniq.many? || followers.uniq.many?
            puts "fiends or followers is valid #{tu.id} #{tu.uid} #{friends.inspect} #{followers.inspect}"
            not_consistent << tu.id
          end

          break if sigint || failed
        end

        processed += twitter_users.size
        avg = '%3.1f' % ((Time.zone.now - start_time) / processed)
        puts "#{Time.zone.now}: processed #{processed}, avg #{avg}, #{twitter_users[0].id} - #{twitter_users[-1].id}"

        break if sigint || failed
      end
    end

    puts "not_found #{not_found.inspect}" if not_found.any?
    puts "not_consistent #{not_consistent.inspect}" if not_consistent.any?
    puts "repair #{(sigint || failed ? 'suspended:' : 'finished:')}"
    puts "  start: #{start}, last: #{last}, processed: #{processed}, not_found: #{not_found.size}, not_consistent: #{not_consistent.size}, started_at: #{start_time}, finished_at: #{Time.zone.now}"
  end

  # desc 'fix'
  # task fix: :environment do
  #   ids = ENV['IDS'].remove(/ /).split(',').map(&:to_i)
  #   ids.each { |id| RepairTwitterUserWorker.new.perform(id) }
  # end

  namespace :fix do
    desc 'not_found'
    task not_found: :environment do
      ids = ENV['IDS'].remove(/ /).split(',').map(&:to_i)
      uids = TwitterUser.where(id: ids).pluck(:uid).uniq.map(&:to_i)

      begin
        t_users = Bot.api_client.users(uids)
      rescue => e
        puts "#{e.class} #{e.message} #{uids.size}"
        t_users = []
      end

      puts("\e[31m" + "not found #{(uids - t_users.map(&:id)).inspect}" + "\e[0m") if uids.size != t_users.size

      users = t_users.map { |t_user| [t_user.id, t_user.screen_name, t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1] }
      TwitterDB::User.import_each_slice(users)

      puts "ids: #{ids.size}, uids: #{uids.size}, t_users: #{t_users.size}, users: #{users.size}"
    end

    desc 'not_consistent'
    task not_consistent: :environment do
      ids = ENV['IDS'].remove(/ /).split(',').map(&:to_i)

      ids.each do |twitter_user_id|
        twitter_user = TwitterUser.find(twitter_user_id)
        uid = twitter_user.uid.to_i

        if twitter_user.user_id == -1
          client = Bot.api_client
        else
          user = User.find_by(id: twitter_user.user_id, authorized: true)

          if user
            client = user.api_client

            begin
              client.verify_credentials
            rescue Twitter::Error::Unauthorized => e
              if e.message == 'Invalid or expired token.'
                user.update(authorized: false)
                client = Bot.api_client
              else
                raise
              end
            end
          else
            client = Bot.api_client
          end
        end

        t_user = client.user(uid)
        if t_user.protected
          puts "Skip because #{t_user.screen_name} is protected. #{twitter_user_id} #{uid}"
          next
        end

        latest = twitter_user.latest?
        if latest
          signatures = [{method: :friend_ids, args: [uid]}, {method: :follower_ids, args: [uid]}]
          friend_uids, follower_uids = client._fetch_parallelly(signatures)

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

        tu = TwitterUser.find(twitter_user_id)

        puts "#{latest} #{tu.id} #{tu.uid} #{[tu.friendships.size, tu.friends_size, tu.followerships.size, tu.followers_size].inspect}"
      end
    end
  end
end