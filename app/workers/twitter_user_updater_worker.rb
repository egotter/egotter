class TwitterUserUpdaterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: 1, backtrace: 3

  # This worker is called with various uids,
  # so you need to do strict validation in this worker.
  def perform(uid)
    @uid = uid
    u = client.user(uid.to_i) && client.user(uid.to_i)
    logger.debug "#{user_name(u)} start"

    if u.friends_count + u.followers_count > TwitterUser::TOO_MANY_FRIENDS
      create_log(uid, false, BackgroundUpdateLog::TooManyFriends)
      return
    end

    if u.protected && u.id.to_i != bot.uid.to_i
      create_log(uid, false, BackgroundUpdateLog::Unauthorized)
      return
    end

    if u.suspended
      create_log(uid, false, BackgroundUpdateLog::Suspended)
      return
    end

    tu = TwitterUser.latest(u.id)

    # if tu.blank?
    #   logger.debug "#{user_name(u)} TwitterUser doesn't exist"
    #   create_log(uid, true, '')
    #   return
    # end

    if tu.present? && (tu.recently_created? || tu.recently_updated?)
      logger.debug "#{user_name(u)} skip(recently created or recently updated)"
      create_log(uid, true, '')
      return
    end

    new_tu = TwitterUser.build(client, u.id)
    if new_tu.save_with_bulk_insert
      logger.debug "#{user_name(u)} create new TwitterUser"
    else
      logger.debug "#{user_name(u)} do nothing(#{new_tu.errors.full_messages})"
    end
    create_log(uid, true, '')

  rescue Twitter::Error::TooManyRequests => e
    logger.warn "#{user_name(u)} #{bot_name(bot)} #{e.message} retry after #{e.rate_limit.reset_in} seconds"
    redis.zrem('update_job_dispatcher:recently_added', uid.to_s)
    create_log(uid, false, BackgroundUpdateLog::TooManyRequests)
  rescue Twitter::Error::Unauthorized => e
    logger.warn "#{user_name(u)} #{bot_name(bot)} #{e.class} #{e.message}"
    create_log(uid, false, BackgroundUpdateLog::Unauthorized)
  end

  def user_name(u)
    "#{u.id},#{u.screen_name}" rescue @uid.to_s
  end

  def bot_name(b)
    "#{b.uid},#{b.screen_name}"
  end

  def create_log(uid, status, reason)
    BackgroundUpdateLog.create(uid: uid, bot_uid: bot.uid, status: status, reason: reason)
  rescue => e
    logger.warn "create_log #{e.message}"
  end

  def redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  # TODO Use the target user's token if I have it.

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
