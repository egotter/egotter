namespace :update_job_dispatcher do
  desc 'Dispatch TwitterUserUpdateJob'
  task run: :environment do
    start_t = Time.zone.now
    puts "[#{start_t}] enqueue start"

    # TODO use queue priority

    key = 'update_job_dispatcher:recently_added'
    zrem_count = redis.zremrangebyscore(key, 0, 2.days.ago.to_i)
    enqueue_count = 0
    already_added_count = 0
    recently_updated_count = 0
    unauthorized_count = 0
    suspended_count = 0
    too_many_friends_count = 0
    enqueue_uids = []

    begin
      uids = client.follower_ids('ego_tter').map { |id| id.to_i }
    rescue Twitter::Error::TooManyRequests => e
      puts "#{bot.screen_name} #{e.message} retry after #{e.rate_limit.reset_in} seconds"
      end_t = Time.zone.now
      puts "[#{Time.now}] enqueue finish (#{end_t - start_t}s)"
      next
    end

    uids.shuffle.each do |uid|
      if redis.zrank(key, uid.to_s).present?
        already_added_count += 1
        next
      end

      if TwitterUser.exists?(uid: uid.to_i) && TwitterUser.latest(uid.to_i).recently_updated?
        recently_updated_count += 1
        next
      end

      if (friend = Friend.find_by(uid: uid.to_i)).present? ||
        (follower = Follower.find_by(uid: uid.to_i)).present?

        _tu = friend.present? ? friend : follower

        if _tu.unauthorized?
          unauthorized_count += 1
          next
        end

        if _tu.suspended_account?
          suspended_count += 1
          next
        end

        if _tu.too_many_friends?
          too_many_friends_count += 1
          next
        end
      end

      TwitterUserUpdaterWorker.perform_async(uid.to_i)
      enqueue_uids << uid.to_i
      redis.zadd(key, now_i, uid.to_s)
      enqueue_count += 1

      break if enqueue_count >= 10
    end


    puts %W(zcard=#{redis.zcard(key)} zrem=#{zrem_count} enqueue=#{enqueue_count}
      already_added=#{already_added_count} recently_updated=#{recently_updated_count}
      unauthorized=#{unauthorized_count} suspended=#{suspended_count} too_many_friends=#{too_many_friends_count}).join(' ')

    end_t = Time.zone.now
    puts "[#{Time.now}] enqueue finish (#{end_t - start_t}s)"
  end

  def now_i
    Time.zone.now.to_i
  end

  def redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  def client
    config = Bot.config
    config.update(access_token: bot.token, access_token_secret: bot.secret)
    c = ExTwitter.new(config)
    c.verify_credentials
    c
  end

  def bot
    @bot ||= Bot.sample
  end
end
