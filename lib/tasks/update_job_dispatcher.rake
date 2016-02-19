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
    min_enqueue_limit = 10
    max_enqueue_limit = 30
    cur_enqueue_limit = (redis.fetch(enqueue_num_key) { min_enqueue_limit }).to_i
    enqueued_count = 0
    unauthorized_count = 0
    suspended_count = 0
    too_many_friends_count = 0
    enqueue_uids = []
    processed_count = -1

    last_logs = BackgroundUpdateLog.order(created_at: :desc).limit(cur_enqueue_limit)
    if last_logs.select { |l| !l.status && l.reason == BackgroundUpdateLog::TOO_MANY_REQUESTS }.any?
      cur_enqueue_limit = min_enqueue_limit
    else
      cur_enqueue_limit += 2
      cur_enqueue_limit = max_enqueue_limit if cur_enqueue_limit > max_enqueue_limit
    end
    redis.set(enqueue_num_key, cur_enqueue_limit)

    begin
      uids = client.follower_ids('ego_tter').map { |id| id.to_i }
    rescue Twitter::Error::TooManyRequests => e
      puts "#{client.screen_name} #{e.message} retry after #{e.rate_limit.reset_in} seconds (#{Time.zone.now - start_t}s)"
      next
    end

    uids.shuffle.each.with_index do |uid, index|
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
      enqueued_count += 1

      if enqueued_count >= cur_enqueue_limit
        processed_count = index + 1
        break
      end
    end

    if processed_count == -1
      processed_count = uids.size
    end

    if enqueued_count < cur_enqueue_limit
      zrem_count = redis.zremrangebyrank(added_key, 0, cur_enqueue_limit - 1)
    end


    debug_info = {
      followers: uids.size,
      'zcard(added)' => redis.zcard(added_key),
      'zcard(too many friends)' => redis.zcard(too_many_friends_key),
      'zcard(unauthorized)' => redis.zcard(unauthorized_key),
      'zrem(added)' => zrem_count,
      min_enqueue_limit: min_enqueue_limit,
      max_enqueue_limit: max_enqueue_limit,
      cur_enqueue_limit: cur_enqueue_limit,
      enqueued_count: enqueued_count,
      processed_count: processed_count,
      already_added: already_added_count,
      already_failed: already_failed_count,
      already_too_many_friends: already_tmf_count,
      already_unauthorized: already_unauthorized_count,
      recently_updated: recently_updated_count,
      'unauthorized(friend)' => unauthorized_count,
      'suspended(friend)' => suspended_count,
      'too_many_friends(friend)' => too_many_friends_count,
      searched_uids: redis.zcard(Redis.background_search_worker_searched_uids_key)
    }
    redis.set(Redis.debug_info_key, debug_info.to_json)

    puts "#{debug_info.map{|k, v| "#{k}=#{v}" }.join(' ')} (#{Time.zone.now - start_t}s)"
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
