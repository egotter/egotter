class CreateTwitterUserWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  BUSY_QUEUE_SIZE = 0

  def perform(values = {})
    user = user_id = uid = client = delay = track = job = nil
    benchmark

    track = Track.find(values['track_id'])
    job = track.jobs.create(values.slice('user_id', 'uid', 'screen_name', 'enqueued_at').merge(worker_class: self.class, jid: jid, started_at: Time.zone.now))

    if self.class == CreateTwitterUserWorker && (job.too_late? || too_busy?(track))
      delay = true
      job.update(error_class: Job::Error::TooOldOrTooBusy, error_message: 'Too old or too busy')
      return DelayedCreateTwitterUserWorker.perform_async(values)
    end

    user = User.find_by(id: job.user_id)
    if user&.unauthorized?
      return job.update(error_class: Job::Error::Unauthorized, error_message: 'Unauthorized')
    end

    user_id = job.user_id
    uid = job.uid
    client = ApiClient.user_or_bot_client(user&.id) { |client_uid| job.update(client_uid: client_uid) }

    creating_uids = Util::CreatingUids.new(Redis.client)
    if creating_uids.exists?(uid)
      return job.update(error_class: Job::Error::RecentlyEnqueued, error_message: 'Recently enqueued')
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

      job.update(error_class: Job::Error::RecordInvalid, error_message: builder.error_message)
      latest = TwitterUser.latest(uid)
      if latest
        latest.increment(:search_count).save
      end
      return
    end

    update_twitter_db_user(twitter_user)

    if twitter_user.save
      twitter_user = TwitterUser.find(twitter_user.id)
      twitter_user.increment(:search_count).save
      job.update(twitter_user_id: twitter_user.id)

      ImportTwitterUserRelationsWorker.perform_async(user_id, uid, twitter_user_id: twitter_user.id, enqueued_at: Time.zone.now, track_id: track.id)
      UpdateUsageStatWorker.perform_async(uid, user_id: user_id, track_id: track.id)
      CreateScoreWorker.perform_async(uid, track_id: track.id)

      return
    end

    latest = TwitterUser.latest(uid)
    if latest
      latest.increment(:search_count).save
      job.update(error_class: Job::Error::NotChanged, error_message: 'Not changed')
      return
    end

    job.update(error_class: Job::Error::RecordInvalid, error_message: twitter_user.errors.full_messages.join(', '))

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

    error_message =
      if e.class == Twitter::Error::TooManyRequests
        (Time.zone.now + e.rate_limit.reset_in.to_i).to_s(:db)
      else
        e.message.truncate(100)
      end
    job.update(error_class: e.class, error_message: error_message)
  rescue Twitter::Error => e
    retry if e.message == 'Connection reset by peer - SSL_connect'

    handle_unknown_exception(e, values)
    job.update(error_class: e.class, error_message: e.message.truncate(100))
  rescue => e
    # ActiveRecord::ConnectionTimeoutError could not obtain a database connection within 5.000 seconds
    handle_unknown_exception(e, values)
    job.update(error_class: e.class, error_message: e.message.truncate(100))
  ensure
    job.update(finished_at: Time.zone.now)
    notify(user, uid) if user

    if delay
      logger.warn "A delay occurs. #{values.slice('track_id', 'user_id', 'uid', 'device_type', 'auto').inspect}"
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

  def notify(login_user, searched_uid)
    searched_user = User.authorized.select(:id).find_by(uid: searched_uid)
    if searched_user && (!login_user || login_user.id != searched_user.id)
      CreateSearchReportWorker.perform_async(searched_user.id)
    end
  end

  def handle_retryable_exception(values, ex)
    params_str = "#{values.slice('track_id', 'user_id', 'uid', 'device_type', 'auto').inspect}"
    sleep_seconds = (ex.class == Twitter::Error::TooManyRequests) ? (ex.rate_limit.reset_in.to_i + 1) : 0

    DelayedCreateTwitterUserWorker.perform_in(sleep_seconds, values)
    logger.warn "Retry(#{ex.class.name.demodulize}) after #{sleep_seconds} seconds. #{params_str}"
  end

  def handle_unknown_exception(ex, values)
    logger.warn "#{ex.class} #{ex.message.truncate(150)} #{values.inspect}"
    logger.info ex.backtrace.join("\n")
  end

  def too_old?(log)
    log.enqueued_at < 1.minutes.ago
  end

  def too_busy?(track)
    Sidekiq::Queue.new(self.class.name).size > BUSY_QUEUE_SIZE && track.auto
  end
end
