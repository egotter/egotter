class CreateTwitterUserWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  BUSY_QUEUE_SIZE = 0

  def before_perform(values)
    @log = BackgroundSearchLog.new(
      session_id:  values.fetch('session_id', ''),
      user_id:     values['user_id'].to_i,
      uid:         values['uid'].to_i,
      screen_name: values.fetch('screen_name', ''),
      action:      values.fetch('action', ''),
      bot_uid:     -100,
      auto:        values.fetch('auto', false),
      message:     '',
      call_count:  -1,
      via:         values.fetch('via', ''),
      device_type: values.fetch('device_type', ''),
      os:          values.fetch('os', ''),
      browser:     values.fetch('browser', ''),
      user_agent:  values.fetch('user_agent', ''),
      referer:     values.fetch('referer', ''),
      referral:    values.fetch('referral', ''),
      channel:     values.fetch('channel', ''),
      medium:      values.fetch('medium', ''),
      error_class: '',
      error_message: '',
      enqueued_at: values.fetch('enqueued_at', Time.zone.now),
      started_at:  values.fetch('started_at', Time.zone.now),
    )
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{values.inspect}"
    @log = BackgroundSearchLog.new(message: '')
  end

  def perform(values = {})
    log = user_id = uid = client = delay = nil
    benchmark

    values['enqueued_at'] = Time.zone.parse(values['enqueued_at']) if values['enqueued_at'].is_a?(String)
    before_perform(values)
    log = @log

    if self.class == CreateTwitterUserWorker && (too_old?(log) || too_busy?(log))
      log = nil
      delay = true
      return DelayedCreateTwitterUserWorker.perform_async(values)
    end

    user = User.find_by(id: log.user_id)
    if user&.unauthorized?
      return log.assign_attributes(status: false, reason: BackgroundSearchLog::Unauthorized::MESSAGE)
    end

    user_id = log.user_id.to_i
    uid = log.uid.to_i
    client = ApiClient.user_or_bot_client(user&.id) { |client_uid| log.bot_uid = client_uid }

    creating_uids = Util::CreatingUids.new(Redis.client)
    if creating_uids.exists?(uid)
      if TwitterUser.exists?(uid: uid)
        return log.assign_attributes(status: true, message: "[#{uid}] is recently created.")
      else
        return log.assign_attributes(status: false, reason: BackgroundSearchLog::SomethingError::MESSAGE, message: "[#{uid}] is recently created.")
      end
    end
    creating_uids.add(uid)

    builder = TwitterUser.builder(uid).client(client).login_user(user)
    twitter_user = builder.build
    unless twitter_user

      begin
        update_twitter_db_user(TwitterUser.build_by_user(client.user(uid)))
      rescue => e
        logger.warn "Relief measures in ##{__method__}: #{e.class} #{e.message} #{uid}"
      end

      latest = TwitterUser.latest(uid)
      if latest
        latest.increment(:search_count).save
        notify(user, latest)
        return log.assign_attributes(status: true, message: builder.error_message)
      else
        return log.assign_attributes(status: false, reason: BackgroundSearchLog::SomethingError::MESSAGE, message: builder.error_message)
      end
    end

    update_twitter_db_user(twitter_user)

    if twitter_user.save
      twitter_user = TwitterUser.find(twitter_user.id)
      twitter_user.increment(:search_count).save

      ImportTwitterUserRelationsWorker.perform_async(user_id, uid.to_i, twitter_user_id: twitter_user.id, 'enqueued_at' => Time.zone.now)
      update_usage_stat(twitter_user)
      create_score(twitter_user)

      notify(user, twitter_user)
      return log.assign_attributes(status: true, message: "[#{twitter_user.id}] is created.")
    end

    latest = TwitterUser.latest(uid)
    if latest
      latest.increment(:search_count).save
      notify(user, latest)
      return log.assign_attributes(status: true, message: 'not changed')
    end

    log.assign_attributes(
      status: false,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{twitter_user.errors.full_messages.join(', ')}."
    )
  rescue Twitter::Error::Forbidden, Twitter::Error::NotFound, Twitter::Error::Unauthorized,
    Twitter::Error::TooManyRequests, Twitter::Error::InternalServerError, Twitter::Error::ServiceUnavailable => e
    case e.class.name.demodulize
      when 'Forbidden'           then handle_forbidden_exception(e, user_id: user_id, uid: uid)
      when 'NotFound'            then handle_not_found_exception(e, user_id: user_id, uid: uid)
      when 'Unauthorized'        then handle_unauthorized_exception(e, user_id: user_id, uid: uid)
      when 'TooManyRequests'     then handle_retryable_exception(values, e)
      when 'InternalServerError' then handle_retryable_exception(values, e)
      when 'ServiceUnavailable'  then handle_retryable_exception(values, e)
      else logger.warn "#{__method__}: #{e.class} #{e.message} #{values.inspect}"
    end

    assign_something_error(e, log)
  rescue Twitter::Error => e
    retry if e.message == 'Connection reset by peer - SSL_connect'

    handle_unknown_exception(e, values)
    assign_something_error(e, log)
  rescue => e
    # ActiveRecord::ConnectionTimeoutError could not obtain a database connection within 5.000 seconds
    handle_unknown_exception(e, values)
    assign_something_error(e, log)
  ensure
    if log
      begin
        log.update!(call_count: (client ? client.call_count : -1), finished_at: Time.zone.now)
      rescue => e
        logger.warn "Creating a log is failed. #{e.class} #{e.message} #{values.inspect}"
      end
    else
      if delay
        logger.warn "A delay occurs. #{values['user_id']} #{values['uid']} #{values['device_type']} #{values['auto']} #{values['enqueued_at']}"
      else
        logger.warn "A log is nil. #{values.inspect}"
      end
    end

    benchmark.finish
  end

  private

  def update_twitter_db_user(twitter_user)
    user = TwitterDB::User.find_or_initialize_by(uid: twitter_user.uid)
    user.assign_attributes(screen_name: twitter_user.screen_name, user_info: twitter_user.user_info)
    user.assign_attributes(friends_size: -1, followers_size: -1) if user.new_record?
    user.save!
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(150)} #{twitter_user.inspect}"
  end

  def update_usage_stat(twitter_user)
    UsageStat.builder(twitter_user.uid).statuses(twitter_user.statuses).build.save!
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(150)} #{twitter_user.inspect}"
  end

  def create_score(twitter_user)
    unless Score.exists?(uid: twitter_user.uid)
      score = Score.builder(twitter_user.uid).build
      if score.valid? && !Score.exists?(uid: twitter_user.uid) # It currently validates only klout_id.
        score.save!
      end
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(150)} #{twitter_user.inspect}"
  end

  def notify(login_user, twitter_user)
    searched_user = User.authorized.find_by(uid: twitter_user.uid)
    if searched_user && (!login_user || login_user.id != searched_user.id)
      CreateSearchReportWorker.perform_async(searched_user.id)
    end
  end

  def handle_retryable_exception(values, ex)
    params_str = "#{values['user_id']} #{values['uid']} #{values['device_type']} #{values['auto']}"

    sleep_seconds =
      (ex.class == Twitter::Error::TooManyRequests) ? (ex&.rate_limit&.reset_in.to_i + 1).seconds : 0

    DelayedCreateTwitterUserWorker.perform_in(sleep_seconds, values)
    logger.warn "Retry(#{ex.class.name.demodulize}) after #{sleep_seconds} seconds. #{params_str}"
  end

  def handle_unknown_exception(ex, values)
    logger.warn "#{ex.class} #{ex.message.truncate(150)} #{values.inspect}"
    logger.info ex.backtrace.join("\n")
  end

  def assign_something_error(ex, log)
    log&.assign_attributes(
      status: false,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      error_class: ex.class,
      error_message: ex.message.truncate(180)
    )
  end

  def too_old?(log)
    log.enqueued_at < 1.minutes.ago
  end

  def too_busy?(log)
    Sidekiq::Queue.new(self.class.name).size > BUSY_QUEUE_SIZE && log.auto
  end
end
