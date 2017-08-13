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

          unless user
            puts "Not found #{tu.id} #{tu.uid}"
            not_found << tu.id
          end

          if tu.need_repair?
            puts "Not consistent #{tu.id} #{tu.uid} [#{tu.friendships.size}, #{tu.friends_size}] [#{tu.followerships.size}, #{tu.followers_size}]"
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
    puts "TwitterUser not_consistent #{not_consistent.inspect.remove(' ')}" if not_consistent.any?
    puts "check #{(sigint ? 'suspended:' : 'finished:')}"
    puts "  start: #{start}, last: #{last}, processed: #{processed}, not_found: #{not_found.size}, not_consistent: #{not_consistent.size}, started_at: #{start_time}, finished_at: #{Time.zone.now}"
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
            signatures = [{method: :friend_ids,   args: [uid]}, {method: :follower_ids, args: [uid]}]
            friend_uids, follower_uids = client._fetch_parallelly(signatures)
          rescue => e
            puts "client.friend_ids: #{e.class} #{e.message} #{twitter_user_id}"
            break
          end

          TwitterDB::Users.fetch_and_import((friend_uids + follower_uids).uniq, client: client)

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

        Unfriendship.import_from!(uid, TwitterUser.calc_removing_uids(uid))
        Unfollowership.import_from!(uid, TwitterUser.calc_removed_uids(uid))

        OneSidedFriendship.import_from!(uid, twitter_user.calc_one_sided_friend_uids)
        OneSidedFollowership.import_from!(uid, twitter_user.calc_one_sided_follower_uids)
        MutualFriendship.import_from!(uid, twitter_user.calc_mutual_friend_uids)

        twitter_user.debug_print_friends
      end
    end
  end
end