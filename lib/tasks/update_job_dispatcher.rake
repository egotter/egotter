namespace :update_job_dispatcher do
  desc 'Dispatch TwitterUserUpdateJob'
  task run: :environment do
    start_t = Time.zone.now

    # TODO use queue priority

    key = 'update_job_dispatcher:recently_added'
    debug_key = 'update_job_dispatcher:debug'
    zremrangebyscore_count = redis.zremrangebyscore(key, 0, 1.day.ago.to_i)
    zremrangebyrank_count = 0
    max_enqueue_count = 10
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
      end_t = Time.zone.now
      puts "#{client.screen_name} #{e.message} retry after #{e.rate_limit.reset_in} seconds (#{end_t - start_t}s)"
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

      BackgroundUpdateWorker.perform_async(uid.to_i)
      enqueue_uids << uid.to_i
      redis.zadd(key, now_i, uid.to_s)
      enqueue_count += 1

      break if enqueue_count >= max_enqueue_count
    end

    if enqueue_count < max_enqueue_count
      zremrangebyrank_count = redis.zremrangebyrank(key, 0, max_enqueue_count * 3)
    end


    debug_info = {
      followers: uids.size,
      zcard: redis.zcard(key),
      zremrangebyscore: zremrangebyscore_count,
      zremrangebyrank: zremrangebyrank_count,
      enqueue: enqueue_count,
      already_added: already_added_count,
      recently_updated: recently_updated_count,
      unauthorized: unauthorized_count,
      suspended: suspended_count,
      too_many_friends: too_many_friends_count
    }
    redis.set(debug_key, debug_info.to_json)

    end_t = Time.zone.now
    puts "#{debug_info.map{|k, v| "#{k}=#{v}" }.join(' ')} (#{end_t - start_t}s)"
  end

  def now_i
    Time.zone.now.to_i
  end

  def redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  def client
    @client ||= Bot.api_client
  end
end
