class ImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  BUSY_QUEUE_SIZE = 0

  def perform(user_id, uid, options = {})
    job = Job.new(
      user_id: user_id,
      uid: uid,
      jid: jid,
      parent_jid: options.fetch('parent_jid', ''),
      worker_class: self.class.name,
      started_at: Time.zone.now
    )
    twitter_user = TwitterUser.latest(uid)
    enqueued_at = options.fetch('enqueued_at', Time.zone.now)
    enqueued_at = Time.zone.parse(enqueued_at) if enqueued_at.is_a?(String)

    if self.class == ImportTwitterUserRelationsWorker
      if enqueued_at < 1.minutes.ago
        return DelayedImportTwitterUserRelationsWorker.perform_async(user_id, uid, options.merge(parent_jid: jid))
      end
    end

    job.assign_attributes(
      screen_name: twitter_user.screen_name,
      twitter_user_id: twitter_user.id,
      enqueued_at: enqueued_at
    )
    parent_jid = jid

    client =
      if user_id == -1
        bot = Bot.sample
        job.client_uid = bot.uid
        Bot.api_client
      else
        user = User.find(user_id)
        job.client_uid = user.uid
        user.api_client
      end

    new_args = [user_id, uid, 'async' => false, 'parent_jid' => parent_jid]

    ImportReplyingRepliedAndFavoritesWorker.new.perform(*new_args)

    if twitter_user.friendless?
      t_user = client.user(uid)
      TwitterDB::User.import_each_slice [TwitterDB::User.to_import_format(t_user)]
    else
      signatures = [{method: :user, args: [uid]}, {method: :friends, args: [uid]}, {method: :followers, args: [uid]}]
      client._fetch_parallelly(signatures) # create caches

      ImportFriendshipsAndFollowershipsWorker.new.perform(*new_args)
      ImportFriendsAndFollowersWorker.new.perform(*new_args)
      ImportInactiveFriendsAndInactiveFollowersWorker.new.perform(*new_args)
    end

    ::Cache::PageCache.new.delete(uid)

    job.update(finished_at: Time.zone.now)

  rescue Twitter::Error::Unauthorized => e
    job.update(error_class: e.class, error_message: e.message, finished_at: Time.zone.now)
    if e.message == 'Invalid or expired token.'
      User.find_by(id: user_id)&.update(authorized: false)
    end

    message = "#{e.class} #{e.message} #{user_id} #{uid}"
    UNAUTHORIZED_MESSAGES.include?(e.message) ? logger.info(message) : logger.warn(message)
  rescue Twitter::Error::TooManyRequests, Twitter::Error::InternalServerError, Twitter::Error::ServiceUnavailable => e
    job.update(error_class: e.class, error_message: e.message, finished_at: Time.zone.now)
    handle_retryable_exception(user_id, uid, e, options)
  rescue Twitter::Error => e
    job.update(error_class: e.class, error_message: e.message, finished_at: Time.zone.now)
    logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
    retry if e.message == 'Connection reset by peer - SSL_connect'
  rescue => e
    job.update(error_class: e.class, error_message: e.message, finished_at: Time.zone.now)
    logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
    logger.info e.backtrace.grep_v(/\.bundle/).join "\n"
  end

  private

  def handle_retryable_exception(user_id, uid, ex, options = {})
    retry_jid = DelayedImportTwitterUserRelationsWorker.perform_async(user_id, uid, options)

    if ex.class == Twitter::Error::TooManyRequests
      logger.warn "#{ex.message} Reset in #{ex&.rate_limit&.reset_in} seconds #{user_id} #{uid} #{retry_jid}"
      logger.info ex.backtrace.grep_v(/\.bundle/).join "\n"
    else
      logger.warn "#{ex.message} #{user_id} #{uid} #{retry_jid}"
    end
  end
end
