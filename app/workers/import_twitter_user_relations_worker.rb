class ImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  BUSY_QUEUE_SIZE = 0

  def perform(user_id, uid, options = {})
    track = Track.find(options['track_id'])
    job = track.jobs.create({user_id: user_id, uid: uid, enqueued_at: options['enqueued_at']}.merge(worker_class: self.class, jid: jid, started_at: Time.zone.now))

    twitter_user = TwitterUser.find(options['twitter_user_id'])
    unless twitter_user.latest?
      logger.warn "A record of TwitterUser is not the latest. #{twitter_user.inspect}"
      twitter_user.update!(friends_size: -1, followers_size: -1)
      return
    end

    job.update(twitter_user_id: twitter_user.id, screen_name: twitter_user.screen_name)

    if self.class == ImportTwitterUserRelationsWorker && job.too_late?
      return DelayedImportTwitterUserRelationsWorker.perform_async(user_id, uid, options)
    end

    latest = TwitterUser.latest_by(uid: twitter_user.uid)
    if latest.id != twitter_user.id
      logger.warn "#{__method__}: latest.id != twitter_user.id #{uid}"
      twitter_user = latest
    end

    client = ApiClient.user_or_bot_client(user_id) { |client_uid| job.update(client_uid: client_uid) }

    do_perform(client, user_id, twitter_user)

  rescue => e
    message = e.message.truncate(100)
    job.update(error_class: e.class, error_message: message)
    logger.warn "#{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.grep_v(/\.bundle/).join "\n"
  ensure
    job.update(finished_at: Time.zone.now)
  end

  def do_perform(client, user_id, twitter_user)
    begin
      uids = FavoriteFriendship.import_by!(twitter_user: twitter_user)
      import_twitter_db_users(client, uids)

      uids = CloseFriendship.import_by!(twitter_user: twitter_user, login_user: User.find_by(id: user_id))
      import_twitter_db_users(client, uids)
    rescue => e
      logger.warn "#{e.class}: #{e.message.truncate(100)}"
      logger.info e.backtrace.join("\n")
    end

    return if twitter_user.no_need_to_import_friendships?

    import_twitter_db_users(client, [twitter_user.uid] + twitter_user.friend_uids + twitter_user.follower_uids)

    import_other_relationships(twitter_user)
  end

  def import_twitter_db_users(client, uids)
    TwitterDB::User::Batch.fetch_and_import(uids, client: client)
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{uids.size}"
    logger.info e.backtrace.join("\n")
  end

  def import_other_relationships(twitter_user)
    [
        Unfriendship,
        Unfollowership,
        OneSidedFriendship,
        OneSidedFollowership,
        MutualFriendship,
        BlockFriendship,
        InactiveFriendship,
        InactiveFollowership,
        InactiveMutualFriendship
    ].each do |klass|
      klass.import_by!(twitter_user: twitter_user)
    rescue => e
      logger.warn "#{klass}#import_by!: #{e.class} #{e.message.truncate(100)} #{twitter_user.inspect}"
      logger.info e.backtrace.join("\n")
    end
  end
end
