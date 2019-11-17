namespace :twitter_users do
  desc 'create'
  task create: :environment do
    sigint = Util::Sigint.new.trap

    uids = ENV['UIDS'].split(',').map(&:to_i)
    created_ids = []
    user_id = -1

    uids.each do |uid|
      request = CreateTwitterUserRequest.create(user_id: user_id, uid: uid)
      twitter_user = request.perform

      if twitter_user
        request.finished!
        created_ids << twitter_user.id

        import_request = ImportTwitterUserRequest.create(user_id: user_id, twitter_user_id: twitter_user.id)
        import_request.perform
        import_request.finished!

        UpdateUsageStatWorker.perform_async(uid, user_id: user_id, enqueued_at: Time.zone.now)
        UpdateAudienceInsightWorker.perform_async(uid, enqueued_at: Time.zone.now, location: 'rake', twitter_user_id: twitter_user.id)
      end

      break if sigint.trapped?
    end

    puts created_ids.join(',') if created_ids.any?
  end

  desc 'Reset'
  task reset: :environment do
    uid = ENV['UID'].to_i
    user = TwitterUser.latest_by(uid: uid)
    puts "#{uid} #{user.reset_data.inspect}"
  end

  desc 'check'
  task check: :environment do
    sigint = Util::Sigint.new.trap

    STDOUT.sync = true
    Rails.logger.level = Logger::WARN
    green = -> (str) {print "\e[32m#{str}\e[0m"}
    last_id = -1
    found_ids = []

    start = ENV['START'] ? ENV['START'].to_i : 1
    columns = %i(id uid friends_size followers_size)

    TwitterUser.select(*columns).find_each(start: start, batch_size: 1000) do |twitter_user|
      if twitter_user.import_batch_failed?
        puts "#{twitter_user.inspect} friendships: #{twitter_user.friendships.size} followerships: #{twitter_user.followerships.size} latest: #{twitter_user.latest?} one: #{twitter_user.one?}"
        found_ids << twitter_user.id
      else
        green.call('.')
      end

      last_id = twitter_user.id

      break if sigint.trapped?
    end

    puts "\n"
    puts "Found ids #{found_ids.join(',')}"
    puts "last id #{last_id}"
  end

  desc 'Update friends_count and followers_count'
  task update_friends_count: :environment do
    sigint = Util::Sigint.new.trap

    start = ENV['START'] ? ENV['START'].to_i : 1
    error_ids = []

    TwitterUser.find_each(start: start, batch_size: 1000) do |twitter_user|
      profile = S3::Profile.find_by(twitter_user_id: twitter_user.id)[:user_info]
      if profile.blank?
        error_ids << twitter_user.id
        next
      end

      user_info = JSON.load(profile)
      if !user_info.has_key?('friends_count') || !user_info.has_key?('followers_count')
        error_ids << twitter_user.id
        next
      end

      twitter_user.update!(friends_count: user_info['friends_count'], followers_count: user_info['followers_count'])

      if sigint.trapped?
        puts "current id #{twitter_user.id}"
        break
      end
    end

    puts error_ids.join(',') if error_ids.any?
  end
end
