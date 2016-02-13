namespace :update_job_dispatcher do
  desc 'Dispatch TwitterUserUpdateJob'
  task run: :environment do
    start_t = Time.zone.now

    # TODO use queue priority

    added_key = Redis.job_dispatcher_added_key
    too_many_friends_key = Redis.background_update_worker_too_many_friends_key
    unauthorized_key = Redis.background_update_worker_unauthorized_key
    enqueue_num_key = Redis.job_dispatcher_enqueue_num_key

    already_added_count = 0
    already_failed_count = 0
    already_tmf_count = 0
    already_unauthorized_count = 0
    recently_updated_count = 0

    zrem_count = 0
    min_enqueue_num = 10
    max_enqueue_num = 30
    current_enqueue_num = (redis.fetch(enqueue_num_key) { min_enqueue_num }).to_i
    enqueue_count = 0
    unauthorized_count = 0
    suspended_count = 0
    too_many_friends_count = 0
    enqueue_uids = []

    last_logs = BackgroundUpdateLog.order(created_at: :desc).limit(current_enqueue_num)
    if last_logs.select { |l| !l.status && l.reason == BackgroundUpdateLog::TOO_MANY_REQUESTS }.any?
      current_enqueue_num = min_enqueue_num
    else
      current_enqueue_num += 2
      current_enqueue_num = max_enqueue_num if current_enqueue_num > max_enqueue_num
    end
    redis.set(enqueue_num_key, current_enqueue_num)

    begin
      uids = client.follower_ids('ego_tter').map { |id| id.to_i }
    rescue Twitter::Error::TooManyRequests => e
      end_t = Time.zone.now
      puts "#{client.screen_name} #{e.message} retry after #{e.rate_limit.reset_in} seconds (#{end_t - start_t}s)"
      next
    end

    uids.shuffle.each do |uid|
      if redis.zrank(added_key, uid.to_s).present?
        already_added_count += 1
        next
      end

      if redis.zrank(too_many_friends_key, uid.to_s).present?
        already_tmf_count += 1
        next
      end

      if redis.zrank(unauthorized_key, uid.to_s).present?
        already_unauthorized_count += 1
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
      redis.zadd(added_key, now_i, uid.to_s)
      enqueue_count += 1

      break if enqueue_count >= current_enqueue_num
    end

    if enqueue_count < current_enqueue_num
      zrem_count = redis.zremrangebyrank(added_key, 0, current_enqueue_num - 1)
    end


    debug_info = {
      followers: uids.size,
      'zcard(added)' => redis.zcard(added_key),
      'zcard(too many friends)' => redis.zcard(too_many_friends_key),
      'zcard(unauthorized)' => redis.zcard(unauthorized_key),
      'zrem(added)' => zrem_count,
      min_enqueue_num: min_enqueue_num,
      max_enqueue_num: max_enqueue_num,
      enqueue_num: current_enqueue_num,
      enqueued_count: enqueue_count,
      already_added: already_added_count,
      already_failed: already_failed_count,
      already_too_many_friends: already_tmf_count,
      already_unauthorized: already_unauthorized_count,
      recently_updated: recently_updated_count,
      'unauthorized(friend)' => unauthorized_count,
      'suspended(friend)' => suspended_count,
      'too_many_friends(friend)' => too_many_friends_count
    }
    redis.set(Redis.debug_info_key, debug_info.to_json)

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
