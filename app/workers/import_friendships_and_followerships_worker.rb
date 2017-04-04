class ImportFriendshipsAndFollowershipsWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id, uid, options = {})
    started_at = Time.zone.now
    chk1 = chk2 = chk3 = nil
    client = ApiClient.user_or_bot_client(user_id)
    twitter_user = TwitterUser.latest(uid)
    async = options.fetch('async', true)
    @retry_count = 0

    signatures = [{method: :friend_ids,   args: [uid]}, {method: :follower_ids, args: [uid]}]
    friend_ids, follower_ids = client._fetch_parallelly(signatures)

    chk1 = Time.zone.now
    _transaction('import Friendship and Followership') do
      Friendship.import_from!(twitter_user.id, friend_ids)
      Followership.import_from!(twitter_user.id, follower_ids)
      twitter_user.update!(followers_size: follower_ids.size, friends_size: friend_ids.size)
    end

    chk2 = Time.zone.now
    _benchmark('import Unfriendship') { Unfriendship.import_from!(uid, TwitterUser.calc_removing_uids(uid)) }
    _benchmark('import Unfollowership') { Unfollowership.import_from!(uid, TwitterUser.calc_removed_uids(uid)) }

    chk3 = Time.zone.now
    _benchmark('import OneSidedFriendship') { OneSidedFriendship.import_from!(uid, twitter_user.calc_one_sided_friend_uids) }
    _benchmark('import OneSidedFollowership') { OneSidedFollowership.import_from!(uid, twitter_user.calc_one_sided_follower_uids) }
    _benchmark('import MutualFriendship') { MutualFriendship.import_from!(uid, twitter_user.calc_mutual_friend_uids) }

  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: user_id, uid: uid, twitter_user_id: twitter_user&.id)
    raise WorkerError.new(self.class, jid) unless async
  rescue ActiveRecord::StatementInvalid => e
    if async
      logger.warn "#{e.message.truncate(100)} #{user_id} #{uid} #{@retry_count} start: #{short_hour(started_at)} chk1: #{short_hour(chk1)} chk2: #{short_hour(chk2)} chk3: #{short_hour(chk3)} finish: #{short_hour(Time.zone.now)}"
      logger.info e.backtrace.join "\n"
    else
      raise WorkerError.new(self.class, jid)
    end
  rescue => e
    if async
      message = e.message.truncate(150)
      logger.warn "#{e.class} #{message} #{user_id} #{uid}"
      logger.info e.backtrace.join "\n"
    else
      raise WorkerError.new(self.class, jid)
    end
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{twitter_user.screen_name}"
  end
end
