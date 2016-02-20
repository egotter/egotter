class BackgroundUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  # This worker is called with various uids,
  # so you need to do strict validation in this worker.
  def perform(uid, options = {})
    @uid = uid
    options = options.with_indifferent_access
    _tu = measure('build(first)') { TwitterUser.build(client, uid.to_i) }
    @sn = _tu.screen_name

    logger.debug "#{user_name} start"

    if _tu.too_many_friends?
      create_log(uid, false, BackgroundUpdateLog::TOO_MANY_FRIENDS, _tu.errors.full_messages)
      redis.zadd(too_many_friends_key, now_i, uid.to_s)
      logger.debug "#{user_name} #{_tu.errors.full_messages}"
      return
    end

    if _tu.unauthorized?
      create_log(uid, false, BackgroundUpdateLog::UNAUTHORIZED, _tu.errors.full_messages)
      redis.zadd(unauthorized_key, now_i, uid.to_s)
      logger.debug "#{user_name} #{_tu.errors.full_messages}"
      return
    end

    if _tu.suspended_account?
      create_log(uid, false, BackgroundUpdateLog::SUSPENDED, _tu.errors.full_messages)
      logger.debug "#{user_name} #{_tu.errors.full_messages}"
      return
    end

    latest_tu = TwitterUser.latest(_tu.uid.to_i)

    if latest_tu.present? && latest_tu.recently_updated?
      latest_tu.update_and_touch
      logger.debug "#{user_name} skip because of recently created(or updated)"
      create_log(uid, false, BackgroundUpdateLog::RECENTLY_CREATED)
      return
    end

    new_tu = measure('build(second)') { TwitterUser.build(client, _tu.uid.to_i, build_relation: true, without_friends: false) }
    if measure('save') { new_tu.save_with_bulk_insert }
      logger.debug "#{user_name} create new TwitterUser"
    else
      logger.debug "#{user_name} do nothing(#{new_tu.errors.full_messages})"
    end
    create_log(uid, true)

    if (user = User.find_by(uid: uid)).present?
      NotificationWorker.perform_async(user.id, type: NotificationWorker::BACKGROUND_UPDATE)
    end rescue nil

  rescue Twitter::Error::TooManyRequests => e
    friends_count = _tu.present? ? "(#{_tu.friends_count},#{_tu.followers_count})" : ''
    logger.warn "#{user_name}#{friends_count} #{bot_name} #{e.message} retry after #{e.rate_limit.reset_in} seconds"
    redis.zrem(Redis.job_dispatcher_added_key, uid.to_s)
    create_log(uid, false, BackgroundUpdateLog::TOO_MANY_REQUESTS)
  rescue Twitter::Error::Unauthorized => e
    logger.warn "#{user_name} #{bot_name} #{e.class} #{e.message}"
    create_log(uid, false, BackgroundUpdateLog::UNAUTHORIZED)
  rescue => e
    logger.warn "#{user_name} #{bot_name} #{e.class} #{e.message}"
    create_log(uid, false, BackgroundUpdateLog::SOMETHING_IS_WRONG, e.message)
    raise e
  end

  def measure(name)
    start = Time.zone.now
    result = yield
    logger.warn "#{user_name} #{name} #{Time.zone.now - start}s"
    result
  end

  def user_name
    "#{@uid},#{@sn}"
  end

  def bot_name
    "#{client.uid},#{client.screen_name}"
  end

  def create_log(uid, status, reason = '', message = '')
    BackgroundUpdateLog.create(uid: uid, screen_name: @sn, bot_uid: client.uid, status: status, reason: reason, message: message, call_count: client.call_count)
  rescue => e
    logger.warn "create_log #{e.message}"
  end

  def redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  def too_many_friends_key
    @too_many_friends_key ||= Redis.background_update_worker_too_many_friends_key
  end

  def unauthorized_key
    @unauthorized_key ||= Redis.background_update_worker_unauthorized_key
  end

  def now_i
    Time.zone.now.to_i
  end

  def client
    @client ||= (User.exists?(uid: @uid) ? User.find_by(uid: @uid).api_client : Bot.api_client)
  end
end
