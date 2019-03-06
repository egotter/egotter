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

    ApiClient.user_or_bot_client(user_id) { |client_uid| job.update(client_uid: client_uid) }

    begin
      uids = FavoriteFriendship.import_by!(twitter_user: twitter_user)
      WriteProfilesToS3Worker.perform_async(uids, user_id: user_id)

      uids = CloseFriendship.import_by!(twitter_user: twitter_user, login_user: User.find_by(id: user_id))
      WriteProfilesToS3Worker.perform_async(uids, user_id: user_id)
    rescue => e
      logger.warn "#{e.class}: #{e.message.truncate(100)}"
      logger.info e.backtrace.join("\n")
    end

    return if twitter_user.no_need_to_import_friendships?

    latest = TwitterUser.latest_by(uid: twitter_user.uid)
    if latest.id != twitter_user.id
      logger.warn "#{__method__}: latest.id != twitter_user.id #{uid}"
    end

    import_other_relationships(latest)

  rescue => e
    message = e.message.truncate(100)
    job.update(error_class: e.class, error_message: message)
    logger.warn "#{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.grep_v(/\.bundle/).join "\n"
  ensure
    job.update(finished_at: Time.zone.now)
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
