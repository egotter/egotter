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
      parent_jid: options.fetch('parent_jid', '').to_s,
      worker_class: self.class.name,
      started_at: Time.zone.now
    )
    twitter_user = TwitterUser.latest(uid)
    enqueued_at = options.fetch('enqueued_at', Time.zone.now)
    enqueued_at = Time.zone.parse(enqueued_at) if enqueued_at.is_a?(String)

    if self.class == ImportTwitterUserRelationsWorker
      if enqueued_at < 1.minutes.ago
        return DelayedImportTwitterUserRelationsWorker.perform_async(user_id, uid, {'parent_jid' => jid}.merge(options))
      end
    end

    job.assign_attributes(
      screen_name: twitter_user.screen_name,
      twitter_user_id: twitter_user.id,
      enqueued_at: enqueued_at
    )

    client = ApiClient.user_or_bot_client(user_id) { |client_uid| job.client_uid = client_uid }

    uids = import_favorite_friend_uids(uid, twitter_user)
    uids += import_close_friend_uids(uid, twitter_user)
    import_twitter_db_users(uids, client)

    return if twitter_user.friendless?

    friend_uids, follower_uids =
      TwitterUser::Batch.fetch_friend_ids_and_follower_ids(uid, client: client) do |ex|
        logger.warn "#{self.class}##{__method__}: #{ex.class} #{ex.message.truncate(100)} #{uid}"
      end
    return if friend_uids.nil? || follower_uids.nil?


    import_friendships(uid, twitter_user, friend_uids, follower_uids)
    latest = TwitterUser.latest(twitter_user.uid)

    begin
      Unfriendship.import_from!(uid, latest.unfriendships)
      Unfollowership.import_from!(uid, latest.unfollowerships)
      OneSidedFriendship.import_from!(uid, twitter_user.calc_one_sided_friend_uids)
      OneSidedFollowership.import_from!(uid, twitter_user.calc_one_sided_follower_uids)
      MutualFriendship.import_from!(uid, twitter_user.calc_mutual_friend_uids)
    rescue => e
      logger.warn "#{__method__}: #{e.class} #{e.message.truncate(100)} #{uid}"
    end

    import_twitter_db_users(friend_uids + follower_uids, client)
    import_twitter_db_friendships(uid, friend_uids, follower_uids)

    import_inactive_friendships(uid, twitter_user)

  rescue Twitter::Error::Unauthorized,
    Twitter::Error::TooManyRequests, Twitter::Error::InternalServerError, Twitter::Error::ServiceUnavailable => e
    case e.class.name.demodulize
      when 'Forbidden'           then handle_forbidden_exception(e, user_id: user_id, uid: uid, twitter_user_id: twitter_user.id)
      when 'NotFound'            then handle_not_found_exception(e, user_id: user_id, uid: uid, twitter_user_id: twitter_user.id)
      when 'Unauthorized'        then handle_unauthorized_exception(e, user_id: user_id, uid: uid, twitter_user_id: twitter_user.id)
      when 'TooManyRequests'     then handle_retryable_exception(e, user_id, uid, twitter_user.id, options)
      when 'InternalServerError' then handle_retryable_exception(e, user_id, uid, twitter_user.id, options)
      when 'ServiceUnavailable'  then handle_retryable_exception(e, user_id, uid, twitter_user.id, options)
      else logger.warn "#{__method__}: #{e.class} #{e.message} #{values.inspect}"
    end

    job.assign_attributes(error_class: e.class, error_message: e.message)
  rescue Twitter::Error => e
    job.assign_attributes(error_class: e.class, error_message: e.message)
    logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
    retry if e.message == 'Connection reset by peer - SSL_connect'
  rescue WorkerError => e
    job.assign_attributes(error_class: e.class, error_message: e.full_message)
    if e.retryable?
      handle_retryable_exception(e.cause, user_id, uid, twitter_user.id, options)
    else
      logger.warn "not retryable #{e.class} #{e.full_message} #{user_id} #{uid} #{twitter_user.id}"
    end
  rescue => e
    message = e.message.truncate(100)
    job.assign_attributes(error_class: e.class, error_message: message)
    logger.warn "#{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.grep_v(/\.bundle/).join "\n"
  ensure
    begin
      job.update!(finished_at: Time.zone.now)
    rescue => e
      logger.warn "#{__method__}: Creating a log is failed. #{e.class} #{e.message}"
    end
  end

  private

  def import_favorite_friend_uids(uid, twitter_user)
    uids = twitter_user.calc_favorite_friend_uids
    FavoriteFriendship.import_from!(uid, uids)
    uids
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(100)} #{twitter_user.inspect}"
    []
  end

  def import_close_friend_uids(uid, twitter_user)
    uids = twitter_user.calc_close_friend_uids
    CloseFriendship.import_from!(uid, uids)
    uids
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(100)} #{twitter_user.inspect}"
    []
  end

  def import_twitter_db_users(uids, client)
    return if uids.blank?
    TwitterDB::User::Batch.fetch_and_import(uids, client: client)
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(100)} #{uids.inspect.truncate(100)}"
  end

  def import_friendships(uid, twitter_user, friend_uids, follower_uids)
    if twitter_user.friends_size != friend_uids.size || twitter_user.followers_size != follower_uids.size
      logger.warn "#{__method__}: It is not consistent. twitter_user(id=#{twitter_user.id}) [#{twitter_user.friends_size}, #{twitter_user.followers_size}] uids [#{friend_uids.size}, #{follower_uids.size}]"
    end

    silent_transaction do
      Friendships.import(twitter_user.id, friend_uids, follower_uids)
      twitter_user.update!(friends_size: friend_uids.size, followers_size: follower_uids.size)
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(100)} #{uid} #{twitter_user.inspect}"
  end

  def import_twitter_db_friendships(uid, friend_uids, follower_uids)
    friends_size = TwitterDB::User.where(uid: friend_uids).size
    followers_size = TwitterDB::User.where(uid: follower_uids).size
    if friends_size != friend_uids.size || followers_size != follower_uids.size
      logger.warn "#{__method__}: It is not consistent. #{uid} persisted [#{friends_size}, #{followers_size}] uids [#{friend_uids.size}, #{follower_uids.size}]"
    end

    silent_transaction do
      TwitterDB::Friendships.import(uid, friend_uids, follower_uids)
      TwitterDB::User.find_by(uid: uid).update!(friends_size: friend_uids.size, followers_size: follower_uids.size)
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(100)} #{uid}"
  end

  def import_inactive_friendships(uid, twitter_user)
    friends = twitter_user.friends
    followers = twitter_user.followers

    mutual_friend_uids = friends.map(&:uid) & followers.map(&:uid)
    mutual_friends = friends.select { |friend| mutual_friend_uids.include? friend.uid }

    InactiveFriendship.import_from!(uid, TwitterUser.select_inactive_users(friends).map(&:uid))
    InactiveFollowership.import_from!(uid, TwitterUser.select_inactive_users(followers).map(&:uid))
    InactiveMutualFriendship.import_from!(uid, TwitterUser.select_inactive_users(mutual_friends).map(&:uid))
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(100)} #{uid}"
  end

  def silent_transaction(retri: false, retry_limit: 3, retry_timeout: 10.seconds, retry_message: '', &block)
    retry_count = 0
    start_time = Time.zone.now

    begin
      Rails.logger.silence { ActiveRecord::Base.transaction(&block) }
    rescue ActiveRecord::StatementInvalid => e
      if retri && e.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
        if retry_count >= retry_limit || (Time.zone.now - start_time) > retry_timeout
          raise
        end

        retry_count += 1
        sleep_seconds = rand
        logger.info "#{__method__}: #{retry_count}/#{retry_limit} #{retry_message}"
        sleep(sleep_seconds)
        retry
      else
        raise
      end
    end
  end

  def handle_retryable_exception(ex, user_id, uid, twitter_user_id, options = {})
    params_str = "#{user_id} #{uid} #{twitter_user_id}"

    sleep_seconds =
      (ex.class == Twitter::Error::TooManyRequests) ? (ex&.rate_limit&.reset_in.to_i + 1).seconds : 0

    DelayedImportTwitterUserRelationsWorker.perform_in(sleep_seconds, user_id, uid, {'parent_jid' => jid}.merge(options))
    logger.warn "Retry(#{ex.class.name.demodulize}) after #{sleep_seconds} seconds. #{params_str}"
  end
end
