class ImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(user_id, uid, options = {})
    options = options.with_indifferent_access
    "#{user_id}-#{uid}-#{options['twitter_user_id']}"
  end

  def unique_in
    5.minutes
  end

  def expire_in
    1.minute
  end

  def after_expire(*args)
    DelayedImportTwitterUserRelationsWorker.perform_async(*args)
  end

  # options:
  #   twitter_user_id
  def perform(user_id, uid, options = {})
    twitter_user = TwitterUser.find(options['twitter_user_id'])

    latest = TwitterUser.latest_by(uid: twitter_user.uid)
    if latest.id != twitter_user.id
      logger.warn "twitter_user_id is not the latest. Continue to processing #{user_id} #{uid} #{options.inspect}"
      twitter_user = latest
    end

    request = ImportTwitterUserRequest.create!(user_id: user_id, twitter_user: twitter_user)
    request.perform!
    request.finished!

  rescue => e
    logger.warn "#{e.class} #{e.message.truncate(100)} #{user_id} #{uid} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
