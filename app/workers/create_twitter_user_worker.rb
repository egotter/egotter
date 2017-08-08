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
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{values.inspect}"
    @log = BackgroundSearchLog.new(message: '')
  end

  def perform(values = {})
    log = user_id = uid = client = delay = nil
    benchmark

    values['enqueued_at'] = Time.zone.parse(values['enqueued_at']) if values['enqueued_at'].is_a?(String)
    before_perform(values)
    log = @log

    if self.class == CreateTwitterUserWorker
      if log.enqueued_at < 1.minutes.ago || (Sidekiq::Queue.new(self.class.name).size > BUSY_QUEUE_SIZE && log.auto)
        log = nil
        delay = true
        return DelayedCreateTwitterUserWorker.perform_async(values)
      end
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
      latest = TwitterUser.latest(uid)
      if latest
        latest.increment(:search_count).save
        notify(user, latest)
        return log.assign_attributes(status: true, message: builder.error_message)
      else
        return log.assign_attributes(status: false, reason: BackgroundSearchLog::SomethingError::MESSAGE, message: builder.error_message)
      end
    end

    if twitter_user.save
      twitter_user = TwitterUser.find(twitter_user.id)
      twitter_user.increment(:search_count).save

      update_twitter_db_user(twitter_user)
      ImportTwitterUserRelationsWorker.perform_async(user_id, uid.to_i, 'queued_at' => Time.zone.now, 'enqueued_at' => Time.zone.now)
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
      else logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{values.inspect}"
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
        logger.warn "#{self.class}##{__method__}: Creating a log is failed. #{e.class} #{e.message} #{values.inspect}"
      end
    else
      comment = delay ? 'A log is nil.' : 'A delay occurs.'
      logger.warn "#{self.class}##{__method__}: #{comment} #{values.inspect}"
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
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{twitter_user.inspect}"
  end

  def update_usage_stat(twitter_user)
    UsageStat.builder(twitter_user.uid).statuses(twitter_user.statuses).build.save!
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{twitter_user.inspect}"
  end

  def create_score(twitter_user)
    unless Score.exists?(uid: twitter_user.uid)
      score = Score.builder(twitter_user.uid).build
      score.save! if score.valid? # It currently validates only klout_id.
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{twitter_user.inspect}"
  end

  def notify(login_user, tu)
    searched_user = User.find_by(uid: tu.uid)
    return if searched_user.nil?

    if login_user.nil? || login_user.id != searched_user.id
      %w(dm onesignal).each do |medium|
        CreateNotificationMessageWorker.perform_async(searched_user.id, tu.uid.to_i, tu.screen_name, type: 'search', medium: medium)
      end
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user.id} #{tu.inspect}"
  end

  def handle_retryable_exception(values, ex)
    retry_jid = DelayedCreateTwitterUserWorker.perform_async(values)

    if ex.class == Twitter::Error::TooManyRequests
      logger.warn "recover #{ex.message} Reset in #{ex&.rate_limit&.reset_in} seconds #{values['user_id']} #{values['uid']} #{retry_jid}"
      logger.info ex.backtrace.grep_v(/\.bundle/).join "\n"
    else
      logger.warn "recover #{ex.class.name.demodulize} #{values['user_id']} #{values['uid']} #{retry_jid}"
    end
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
end
