class BackgroundUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  # This worker is called with various uids,
  # so you need to do strict validation in this worker.
  def perform(uid, options = {})
    @uid = uid
    options = options.with_indifferent_access
    _tu = TwitterUser.build(client, uid.to_i, all: false)

    logger.debug "#{user_name(_tu)} start"

    if _tu.too_many_friends?
      create_log(uid, false, BackgroundUpdateLog::TooManyFriends, _tu.errors.full_messages)
      redis.zadd(failed_key, now_i, uid.to_s)
      logger.debug "#{user_name(_tu)} #{_tu.errors.full_messages}"
      return
    end

    if _tu.unauthorized?
      create_log(uid, false, BackgroundUpdateLog::Unauthorized, _tu.errors.full_messages)
      redis.zadd(failed_key, now_i, uid.to_s)
      logger.debug "#{user_name(_tu)} #{_tu.errors.full_messages}"
      return
    end

    if _tu.suspended_account?
      create_log(uid, false, BackgroundUpdateLog::Suspended, _tu.errors.full_messages)
      logger.debug "#{user_name(_tu)} #{_tu.errors.full_messages}"
      return
    end

    latest_tu = TwitterUser.latest(_tu.uid.to_i)

    if latest_tu.present? && (latest_tu.recently_created? || latest_tu.recently_updated?)
      latest_tu.update_and_touch
      logger.debug "#{user_name(_tu)} skip(recently created or recently updated)"
      create_log(uid, true)
      return
    end

    new_tu = TwitterUser.build(client, _tu.uid.to_i)
    if new_tu.save_with_bulk_insert
      logger.debug "#{user_name(_tu)} create new TwitterUser"
    else
      logger.debug "#{user_name(_tu)} do nothing(#{new_tu.errors.full_messages})"
    end
    create_log(uid, true)

    if (user = User.find_by(uid: uid)).present?
      NotificationWorker.perform_async(user.id, text: 'update')
    end rescue nil

  rescue Twitter::Error::TooManyRequests => e
    friends_count = "(#{_tu.friends_count},#{_tu.followers_count})" if _tu.present?
    logger.warn "#{user_name(_tu)}#{friends_count} #{bot_name(client)} #{e.message} retry after #{e.rate_limit.reset_in} seconds"
    redis.zrem('update_job_dispatcher:recently_added', uid.to_s)
    create_log(uid, false, BackgroundUpdateLog::TooManyRequests)
  rescue Twitter::Error::Unauthorized => e
    logger.warn "#{user_name(_tu)} #{bot_name(client)} #{e.class} #{e.message}"
    create_log(uid, false, BackgroundUpdateLog::Unauthorized)
  rescue => e
    logger.warn "#{user_name(_tu)} #{bot_name(client)} #{e.class} #{e.message}"
    create_log(uid, false, BackgroundUpdateLog::SomethingIsWrong, e.message)
    raise e
  end

  def user_name(tu)
    "#{tu.uid},#{tu.screen_name}" rescue @uid.to_s
  end

  def bot_name(b)
    "#{b.uid},#{b.screen_name}"
  end

  def create_log(uid, status, reason = '', message = '')
    BackgroundUpdateLog.create(uid: uid, bot_uid: client.uid, status: status, reason: reason, message: message)
  rescue => e
    logger.warn "create_log #{e.message}"
  end

  def redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  def failed_key
    @key ||= Redis.background_update_worker_recently_failed_key
  end

  def now_i
    Time.zone.now.to_i
  end

  def client
    @client ||= (User.exists?(uid: @uid) ? User.find_by(uid: @uid).api_client : Bot.api_client)
  end
end
