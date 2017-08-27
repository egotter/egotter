namespace :repair do
  desc 'check'
  task check: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    start = ENV['START'] ? ENV['START'].to_i : 1
    not_found = []
    not_consistent = []
    processed = 0
    start_time = Time.zone.now

    columns = %i(id uid friends_size followers_size)
    TwitterUser.select(*columns).find_each(start: start, batch_size: 1000) do |twitter_user|

      unless TwitterDB::User.exists?(uid: twitter_user.uid)
        puts "Not found #{twitter_user.id} #{twitter_user.uid}"
        not_found << twitter_user.id
      end

      if twitter_user.need_repair?
        print "Not consistent #{twitter_user.id} #{twitter_user.uid} "
        twitter_user.reload.debug_print_friends
        not_consistent << twitter_user.id
      end

      processed += 1

      if processed % 1000 == 0
        avg = '%3.1f' % ((Time.zone.now - start_time) / processed)
        puts "#{Time.zone.now}: processed #{processed}, avg #{avg}"
      end

      break if sigint
    end

    puts "TwitterDB::User not_found #{not_found.inspect.remove(' ')}" if not_found.any?
    puts "TwitterUser not_consistent #{not_consistent.inspect.remove(' ')}" if not_consistent.any?
    puts "check #{(sigint ? 'suspended:' : 'finished:')}"
    puts "  start: #{start}, processed: #{processed}, not_found: #{not_found.size}, not_consistent: #{not_consistent.size}, started_at: #{start_time}, finished_at: #{Time.zone.now}"
  end

  namespace :fix do
    desc 'not_consistent'
    task not_consistent: :environment do
      twitter_user_ids = ENV['TWITTER_USER_IDS'].remove(/ /).split(',').map(&:to_i)

      twitter_user_ids.each do |twitter_user_id|
        twitter_user = TwitterUser.find(twitter_user_id)
        uid = twitter_user.uid.to_i

        if twitter_user.latest?
          client = ApiClient.better_client(uid, twitter_user.user_id)

          begin
            t_user = client.user(uid)
          rescue => e
            puts "client.user: #{e.class} #{e.message} #{twitter_user_id}"
            break
          end

          begin
            friend_uids, follower_uids = client.friend_ids_and_follower_ids(uid)
          rescue => e
            puts "client.friend_ids: #{e.class} #{e.message} #{twitter_user_id}"
            break
          end

          TwitterDB::User::Batch.fetch_and_import((friend_uids + follower_uids).uniq, client: client)

          ActiveRecord::Base.transaction do
            twitter_user.update!(user_info: TwitterUser.collect_user_info(t_user), friends_size: friend_uids.size, followers_size: follower_uids.size)
            Friendships.import(twitter_user.id, friend_uids, follower_uids)
          end
        else
          ActiveRecord::Base.transaction do
            twitter_user.update!(friends_size: 0, followers_size: 0)
            Friendships.import(twitter_user.id, [], [])
          end
        end

        twitter_user = TwitterUser.find(twitter_user_id)
        latest = TwitterUser.latest(twitter_user.uid)

        Unfriendship.import_from!(uid, latest.unfriendships)
        Unfollowership.import_from!(uid, latest.unfollowerships)

        OneSidedFriendship.import_from!(uid, twitter_user.calc_one_sided_friend_uids)
        OneSidedFollowership.import_from!(uid, twitter_user.calc_one_sided_follower_uids)
        MutualFriendship.import_from!(uid, twitter_user.calc_mutual_friend_uids)

        print "#{twitter_user.id} "
        twitter_user.debug_print_friends
      end
    end
  end
end