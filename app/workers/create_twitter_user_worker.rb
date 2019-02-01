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
    job = track.jobs.create!(values.slice('user_id', 'uid', 'screen_name', 'enqueued_at').merge(worker_class: self.class, jid: jid, started_at: Time.zone.now))

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

    if Util::CreateRequests.exists?(uid)
      return job.update(error_class: Job::Error::RecentlyEnqueued, error_message: 'Recently enqueued')
    end
    Util::CreateRequests.add(uid)

    begin
      twitter_user = build_twitter_user(client, user, uid)
      TwitterDB::User.import_by(twitter_user: twitter_user)
      save_twitter_user(twitter_user)
    rescue Job::Error => e
      job.update(error_class: e.class, error_message: e.message)
    else
      job.update(twitter_user_id: twitter_user.id)

      ImportTwitterUserRelationsWorker.perform_async(user_id, uid, twitter_user_id: twitter_user.id, enqueued_at: Time.zone.now, track_id: track.id)
      UpdateUsageStatWorker.perform_async(uid, user_id: user_id, track_id: track.id)
      CreateScoreWorker.perform_async(uid, track_id: track.id)
    end

    # At this point:
    # Saved:     friends_size, followers_size, statuses, mentions, search_results, favorites
    # NOT saved: friendships, followerships

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

    if e.class == Twitter::Error::TooManyRequests
      Util::TooManyRequestsRequests.add(user_id)
      ResetTooManyRequestsWorker.perform_in(e.rate_limit.reset_in.to_i, user_id)
    end

    error_message =
      if e.class == Twitter::Error::TooManyRequests
        (Time.zone.now + e.rate_limit.reset_in.to_i).to_s(:db)
      else
        e.message.truncate(100)
      end
    job.update(error_class: e.class, error_message: error_message)
  rescue Twitter::Error => e
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

  def build_twitter_user(client, user, uid, builder: nil)
    builder = TwitterUser.builder(uid).client(client).login_user(user) unless builder
    twitter_user = builder.build

    if twitter_user.invalid?
      TwitterDB::User.import_by(twitter_user: twitter_user)
      raise Job::Error::RecordInvalid.new(twitter_user.errors.full_messages.join(', '))
    end

    twitter_user
  end

  def save_twitter_user(twitter_user)
    unless twitter_user.save
      if TwitterUser.exists?(uid: twitter_user.uid)
        raise Job::Error::NotChanged.new('Not changed')
      else
        raise Job::Error::RecordInvalid.new(twitter_user.errors.full_messages.join(', '))
      end
    end
  end

  private

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
