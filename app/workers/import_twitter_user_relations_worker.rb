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

    begin
      signatures = [{method: :friend_ids,   args: [uid]}, {method: :follower_ids, args: [uid]}]
      friend_uids, follower_uids = client._fetch_parallelly(signatures)
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(100)} #{uid}"
      friend_uids, follower_uids = [], []
    end

    return if friend_uids.empty? && follower_uids.empty?


    import_friendships(uid, twitter_user, friend_uids, follower_uids)
    import_unfriendships(uid)
    import_one_sided_friendships(uid, twitter_user)

    begin
      import_twitter_db_users(friend_uids + follower_uids, client)

      silent_transaction do
        TwitterDB::Friendship.import_from!(uid, friend_uids)
        TwitterDB::Followership.import_from!(uid, follower_uids)
        TwitterDB::User.find_by(uid: uid).update!(friends_size: friend_uids.size, followers_size: follower_uids.size)
      end
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(100)} #{uid}"
    end

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
      else logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{values.inspect}"
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
      logger.warn "#{self.class}##{__method__}: Creating a log is failed. #{e.class} #{e.message}"
    end
  end

  private

  def import_favorite_friend_uids(uid, twitter_user)
    uids = twitter_user.calc_favorite_friend_uids
    FavoriteFriendship.import_from!(uid, uids)
    uids
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(100)} #{twitter_user.inspect}"
    []
  end

  def import_close_friend_uids(uid, twitter_user)
    uids = twitter_user.calc_close_friend_uids
    CloseFriendship.import_from!(uid, uids)
    uids
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(100)} #{twitter_user.inspect}"
    []
  end

  def import_twitter_db_users(uids, client)
    return if uids.blank?

    t_users = client.users uids.uniq
    if t_users.any?
      users = t_users.map { |user| TwitterDB::User.to_import_format(user) }
      users.sort_by!(&:first)

      silent_transaction(retri: true, retry_message: 'import replying, replied and favoriting') { TwitterDB::User.import_in_batches(users) }
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(100)} #{uids.inspect.truncate(100)}"
  end

  def import_friendships(uid, twitter_user, friend_uids, follower_uids)
    if twitter_user.friends_size != friend_uids.size || twitter_user.followers_size != follower_uids.size
      logger.warn "#{self.class}##{__method__}: It is not consistent. twitter_user(id=#{twitter_user.id}) [#{twitter_user.friends_size}, #{twitter_user.followers_size}] uids [#{friend_uids.size}, #{follower_uids.size}]"
    end

    silent_transaction do
      Friendship.import_from!(twitter_user.id, friend_uids)
      Followership.import_from!(twitter_user.id, follower_uids)
      twitter_user.update!(friends_size: friend_uids.size, followers_size: follower_uids.size)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(100)} #{uid} #{twitter_user.inspect}"
  end

  def import_unfriendships(uid)
    Unfriendship.import_from!(uid, TwitterUser.calc_removing_uids(uid))
    Unfollowership.import_from!(uid, TwitterUser.calc_removed_uids(uid))
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(100)} #{uid}"
  end

  def import_one_sided_friendships(uid, twitter_user)
    OneSidedFriendship.import_from!(uid, twitter_user.calc_one_sided_friend_uids)
    OneSidedFollowership.import_from!(uid, twitter_user.calc_one_sided_follower_uids)
    MutualFriendship.import_from!(uid, twitter_user.calc_mutual_friend_uids)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(100)} #{uid}"
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
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(100)} #{uid}"
  end

  def silent_transaction(retri: false, retry_limit: 3, retry_timeout: 10.seconds, retry_message: '', &block)
    retry_count = 0
    start_time = Time.zone.now

    begin
      Rails.logger.silence { ActiveRecord::Base.transaction(&block) }
    rescue ActiveRecord::StatementInvalid => e
      wait_seconds = Time.zone.now - start_time
      if retri && e.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
        if retry_count >= retry_limit || wait_seconds > retry_timeout
          raise
        end

        retry_count += 1
        sleep_seconds = rand
        logger.info "#{self.class}##{__method__}: #{retry_count}/#{retry_limit} #{retry_message}"
        sleep(sleep_seconds)
        retry
      else
        raise
      end
    end
  end

  def handle_retryable_exception(ex, user_id, uid, twitter_user_id, options = {})
    retry_jid = DelayedImportTwitterUserRelationsWorker.perform_async(user_id, uid, {'parent_jid' => jid}.merge(options))

    if ex.class == Twitter::Error::TooManyRequests
      logger.warn "recover #{ex.message} Reset in #{ex.rate_limit.reset_in} seconds #{user_id} #{uid} #{twitter_user_id} #{retry_jid}"
      logger.info ex.backtrace.grep_v(/\.bundle/).join "\n"
    else
      logger.warn "recover #{ex.class.name.demodulize} #{user_id} #{uid} #{twitter_user_id} #{retry_jid}"
    end
  end
end
