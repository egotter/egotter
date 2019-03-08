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

        UpdateUsageStatWorker.perform_async(uid, user_id: user_id, track_id: nil, enqueued_at: Time.zone.now)
        CreateScoreWorker.perform_async(uid, track_id: nil)
        UpdateAudienceInsightWorker.perform_async(uid, enqueued_at: Time.zone.now)
        DetectFailureWorker.perform_in(60.seconds, twitter_user.id, enqueued_at: Time.zone.now)
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
end
