class ImportInactiveFriendsAndInactiveFollowersWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id, uid, options = {})
    client = ApiClient.user_or_bot_client(user_id)
    twitter_user = TwitterUser.latest(uid)
    async = options.fetch('async', true)

    signatures = [{method: :friends, args: [uid]}, {method: :followers, args: [uid]}]
    friends, followers = client._fetch_parallelly(signatures)

    mutual_friend_uids = friends.map(&:id) & followers.map(&:id)
    mutual_friends = friends.select { |friend| mutual_friend_uids.include? friend.id }

    _benchmark('import InactiveFriendship') { InactiveFriendship.import_from!(uid, TwitterUser.select_inactive_users(friends).map(&:id)) }
    _benchmark('import InactiveFollowership') { InactiveFollowership.import_from!(uid, TwitterUser.select_inactive_users(followers).map(&:id)) }
    _benchmark('import InactiveMutualFriendship') { InactiveMutualFriendship.import_from!(uid, TwitterUser.select_inactive_users(mutual_friends).map(&:id)) }

  rescue => e
    # ActiveRecord::StatementInvalid Mysql2::Error: Deadlock found when trying to get lock;
    if async
      message = e.message.truncate(150)
      logger.warn "#{self.class}: #{e.class} #{message} #{user_id} #{uid}"
      logger.info e.backtrace.join "\n"
    else
      raise WorkerError.new(self.class, jid)
    end
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{twitter_user.screen_name}"
  end
end
