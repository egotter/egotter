class ImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  BUSY_QUEUE_SIZE = 0

  def perform(user_id, uid, options = {})
    track = Track.find(options['track_id'])
    job = track.jobs.create({user_id: user_id, uid: uid, enqueued_at: options['enqueued_at']}.merge(worker_class: self.class, jid: jid, started_at: Time.zone.now))

    twitter_user = TwitterUser.find(options['twitter_user_id'])
    unless twitter_user.latest?
      logger.warn "A fetched record is not the latest one. #{twitter_user.id}"
    end

    job.update(twitter_user_id: twitter_user.id, screen_name: twitter_user.screen_name)

    if self.class == ImportTwitterUserRelationsWorker && job.too_late?
      return DelayedImportTwitterUserRelationsWorker.perform_async(user_id, uid, options)
    end

    client = ApiClient.user_or_bot_client(user_id) { |client_uid| job.update(client_uid: client_uid) }

    uids = FavoriteFriendship.import_by!(twitter_user: twitter_user)
    uids += CloseFriendship.import_by(twitter_user: twitter_user)
    import_twitter_db_users(uids, client)

    return if twitter_user.friendless?

    friend_uids, follower_uids =
      TwitterUser::Batch.fetch_friend_ids_and_follower_ids(uid, client: client) do |ex|
        logger.warn "#{__method__}: #{ex.class} #{ex.message.truncate(100)} #{uid}"
      end
    return if friend_uids.nil? || follower_uids.nil?


    import_friendships(uid, twitter_user, friend_uids, follower_uids)
    latest = TwitterUser.latest_by(uid: twitter_user.uid)

    begin
      Unfriendship.import_by!(twitter_user: latest)
      Unfollowership.import_by!(twitter_user: latest)
      OneSidedFriendship.import_by!(twitter_user: twitter_user)
      OneSidedFollowership.import_by!(twitter_user: twitter_user)
      MutualFriendship.import_by!(twitter_user: twitter_user)
      BlockFriendship.import_by!(twitter_user: latest)
    rescue => e
      logger.warn "#{__method__}: #{e.class} #{e.message.truncate(100)} #{uid}"
    end

    import_twitter_db_users(friend_uids + follower_uids, client)
    import_twitter_db_friendships(uid, friend_uids, follower_uids)

    InactiveFriendship.import_by!(twitter_user: twitter_user)
    InactiveFollowership.import_by!(twitter_user: twitter_user)
    InactiveMutualFriendship.import_by!(twitter_user: twitter_user)

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

    if e.class == Twitter::Error::TooManyRequests
      Util::TooManyRequestsRequests.add(user_id)
      ResetTooManyRequestsWorker.perform_in(e.rate_limit.reset_in.to_i, user_id)
    end

    job.update(error_class: e.class, error_message: e.message)
  rescue Twitter::Error => e
    job.update(error_class: e.class, error_message: e.message)
    logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
  rescue => e
    message = e.message.truncate(100)
    job.update(error_class: e.class, error_message: message)
    logger.warn "#{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.grep_v(/\.bundle/).join "\n"
  ensure
    job.update(finished_at: Time.zone.now)
  end

  private

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
    params_str = "#{options['track_id']} #{user_id} #{uid} #{twitter_user_id}"
    sleep_seconds =(ex.class == Twitter::Error::TooManyRequests) ? (ex.rate_limit.reset_in.to_i + 1) : 0

    DelayedImportTwitterUserRelationsWorker.perform_in(sleep_seconds, user_id, uid, options)
    logger.warn "Retry(#{ex.class.name.demodulize}) after #{sleep_seconds} seconds. #{params_str}"
  end
end
