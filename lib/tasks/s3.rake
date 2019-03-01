namespace :s3 do
  desc 'Find broken data'
  task check: :environment do
    sigint = Util::Sigint.new.trap

    start_id = ENV['START'] ? ENV['START'].to_i : 1
    start = Time.zone.now
    processed_count = 0
    found_ids = []
    S3::Friendship.cache_enabled = false
    S3::Followership.cache_enabled = false
    S3::Profile.cache_enabled = false

    print = -> (reason, user) do
      puts "#{reason}\t#{user.id}\t#{user.uid}\t#{user.screen_name}\t#{user.friends_size}\t#{user.followers_size}"
    end

    check_relationship = -> (klass, uids_key, size_key, twitter_user) do
      unless klass.exists?(twitter_user_id: twitter_user.id)
        puts "Not found #{twitter_user.id}"
        found_ids << twitter_user.id
        next
      end

      relationship = klass.find_by(twitter_user_id: twitter_user.id)
      if relationship.empty?
        print.call('Empty', twitter_user)
        found_ids << twitter_user.id
        next
      end

      if twitter_user.id != relationship[:twitter_user_id] ||
          twitter_user.uid != relationship[:uid] ||
          twitter_user.screen_name != relationship[:screen_name]

        print.call('Keys', twitter_user)
        found_ids << twitter_user.id
        next
      end

      if twitter_user.send(size_key) != relationship[uids_key].size
        print.call("#{size_key} #{relationship[uids_key].size} is mismatch", twitter_user)
        found_ids << twitter_user.id
      end
    end

    check_profile = -> (twitter_user) do
      unless S3::Profile.exists?(twitter_user_id: twitter_user.id)
        puts "Not found #{twitter_user.id}"
        found_ids << twitter_user.id
        next
      end

      profile = S3::Profile.find_by(twitter_user_id: twitter_user.id)
      if profile.blank? ||
          profile[:user_info].blank? ||
          profile[:user_info] == '{}'

        print.call('Empty', twitter_user)
        found_ids << twitter_user.id
      end
    end

    (start_id..(TwitterUser.maximum(:id))).each do |candidate_id|
      # next unless candidate_id % 100 == 0
      puts "#{now = Time.zone.now} #{candidate_id} #{(now - start) / processed_count}" if processed_count % 1000 == 0
      processed_count += 1

      twitter_user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size).find_by(id: candidate_id)
      next unless twitter_user

      check_relationship.call(S3::Friendship, :friend_uids, :friends_size, twitter_user)
      check_relationship.call(S3::Followership, :follower_uids, :followers_size, twitter_user)
      check_profile.call(twitter_user)

      break if sigint.trapped?
    end

    puts found_ids.join(',') if found_ids.any?

    puts Time.zone.now - start
  end
end
