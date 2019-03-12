class ImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(user_id, uid, options = {})
    options = options.with_indifferent_access
    "#{user_id}-#{uid}-#{options['twitter_user_id']}"
  end

  def expire_in
    1.minute
  end

  def after_expire(*args)
    DelayedImportTwitterUserRelationsWorker.perform_async(*args)
  end

  def perform(user_id, uid, options = {})
    track = Track.find(options['track_id'])

    job_attrs = {user_id: user_id, uid: uid, enqueued_at: options['enqueued_at']}.
        merge(worker_class: self.class, jid: jid, started_at: Time.zone.now)
    job = track.jobs.create(job_attrs)

    twitter_user = TwitterUser.find(options['twitter_user_id'])
    unless twitter_user.latest?
      logger.warn "A record of TwitterUser is not the latest. #{twitter_user.inspect}"
      twitter_user.update!(friends_size: -1, followers_size: -1)
      return
    end

    job.update(twitter_user_id: twitter_user.id, screen_name: twitter_user.screen_name)

    latest = TwitterUser.latest_by(uid: twitter_user.uid)
    if latest.id != twitter_user.id
      logger.warn "#{__method__}: latest.id != twitter_user.id #{uid}"
      twitter_user = latest
    end

    request = ImportTwitterUserRequest.create(user_id: user_id, twitter_user: twitter_user)
    request.perform!
    request.finished!

  rescue => e
    message = e.message.truncate(100)
    job.update(error_class: e.class, error_message: message)
    logger.warn "#{e.class} #{message} #{user_id} #{uid} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  ensure
    job.update(finished_at: Time.zone.now)
  end
end
