class BackgroundUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  # This worker is called with various uids,
  # so you need to do strict validation in this worker.
  def perform(uid, options = {})
    @uid = uid
    options = options.with_indifferent_access
    first_tu = measure('build(first)') { TwitterUser.build(client, uid.to_i, user_id: user_id) }
    @sn = first_tu.screen_name

    logger.debug "#{user_name} start"

    if first_tu.too_many_friends?
      create_log(uid, false, BackgroundUpdateLog::TOO_MANY_FRIENDS, first_tu.errors.full_messages)
      redis.zadd(too_many_friends_key, now_i, uid.to_s)
      logger.debug "#{user_name} #{first_tu.errors.full_messages}"
      return
    end

    if first_tu.unauthorized?
      create_log(uid, false, BackgroundUpdateLog::UNAUTHORIZED, first_tu.errors.full_messages)
      redis.zadd(unauthorized_key, now_i, uid.to_s)
      logger.debug "#{user_name} #{first_tu.errors.full_messages}"
      return
    end

    if first_tu.suspended_account?
      create_log(uid, false, BackgroundUpdateLog::SUSPENDED, first_tu.errors.full_messages)
      logger.debug "#{user_name} #{first_tu.errors.full_messages}"
      return
    end

    latest_tu = TwitterUser.latest(first_tu.uid.to_i, user_id)

    if latest_tu.present? && latest_tu.recently_updated?
      latest_tu.update_and_touch
      logger.debug "#{user_name} skip because of recently created(or updated)"
      create_log(uid, false, BackgroundUpdateLog::RECENTLY_CREATED)
      return
    end

    new_tu = measure('build(second)') { TwitterUser.build(client, first_tu.uid.to_i, user_id: user_id, build_relation: true, without_friends: false) }
    if measure('save') { new_tu.save_with_bulk_insert }
      logger.debug "#{user_name} create new TwitterUser"
    else
      logger.debug "#{user_name} do nothing(#{new_tu.errors.full_messages})"
    end
    create_log(uid, true)

    if (user = User.find_by(uid: uid)).present?
      BackgroundNotificationWorker.perform_async(user.id, BackgroundNotificationWorker::UPDATE)
    end

  rescue Twitter::Error::TooManyRequests => e
    friends_count = first_tu.present? ? "(#{first_tu.friends_count},#{first_tu.followers_count})" : ''
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
    logger.warn "#{self.class}##{__method__} #{e.message}"
  end

  def redis
    @redis ||= Redis.client
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

  def user_id
    @user_id ||= (User.exists?(uid: @uid) ? User.find_by(uid: @uid).id : -1)
  end

  def client
    @client ||= (User.exists?(uid: @uid) ? User.find_by(uid: @uid).api_client : Bot.api_client)
  end
end
