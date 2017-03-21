class ImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  BUSY_QUEUE_SIZE = 0

  def perform(user_id, uid)
    twitter_user = TwitterUser.latest(uid)
    client = user_id == -1 ? Bot.api_client : User.find(user_id).api_client

    ImportReplyingRepliedAndFavoritesWorker.new.perform(user_id, uid, 'async' => false)

    if twitter_user.friendless?
      t_user = client.user(uid)
      TwitterDB::User.import_each_slice [to_array(t_user)]
    else
      signatures = [{method: :user, args: [uid]}, {method: :friends, args: [uid]}, {method: :followers, args: [uid]}]
      client._fetch_parallelly(signatures) # create caches

      ImportFriendshipsAndFollowershipsWorker.perform_async(user_id, uid)
      ImportFriendsAndFollowersWorker.perform_async(user_id, uid)
      ImportInactiveFriendsAndInactiveFollowersWorker.perform_async(user_id, uid)
    end

    # TODO remove page cache

  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      User.find_by(id: user_id)&.update(authorized: false)
    end

    message = "#{e.class} #{e.message} #{user_id} #{uid}"
    UNAUTHORIZED_MESSAGES.include?(e.message) ? logger.info(message) : logger.warn(message)
  rescue Twitter::Error::TooManyRequests, Twitter::Error::InternalServerError, Twitter::Error::ServiceUnavailable => e
    handle_retryable_exception(user_id, uid, e)
  rescue Twitter::Error => e
    logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
    retry if e.message == 'Connection reset by peer - SSL_connect'
  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
    logger.info e.backtrace.grep_v(/\.bundle/).join "\n"
  end

  private

  def to_array(user)
    [user.id, user.screen_name, user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1]
  end

  def handle_retryable_exception(user_id, uid, ex)
    retry_jid = DelayedImportTwitterUserRelationsWorker.perform_async(user_id, uid)

    if ex.class == Twitter::Error::TooManyRequests
      logger.warn "#{ex.message} Reset in #{ex&.rate_limit&.reset_in} seconds #{user_id} #{uid} #{retry_jid}"
      logger.info ex.backtrace.grep_v(/\.bundle/).join "\n"
    else
      logger.warn "#{ex.message} #{user_id} #{uid} #{retry_jid}"
    end
  end
end
