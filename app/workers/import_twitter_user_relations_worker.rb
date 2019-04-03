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
    twitter_user = TwitterUser.find(options['twitter_user_id'])
    unless twitter_user.latest?
      logger.warn "A record of TwitterUser is not the latest. #{twitter_user.inspect}"
      twitter_user.update!(friends_size: -1, followers_size: -1)
      return
    end

    latest = TwitterUser.latest_by(uid: twitter_user.uid)
    if latest.id != twitter_user.id
      logger.warn "#{__method__}: latest.id != twitter_user.id #{uid}"
      twitter_user = latest
    end

    request = ImportTwitterUserRequest.create(user_id: user_id, twitter_user: twitter_user)
    request.perform!
    request.finished!

  rescue => e
    logger.warn "#{e.class} #{e.message.truncate(100)} #{user_id} #{uid} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
