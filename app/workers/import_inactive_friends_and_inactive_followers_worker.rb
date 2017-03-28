class ImportInactiveFriendsAndInactiveFollowersWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id, uid, options = {})
    client = user_id == -1 ? Bot.api_client : User.find(user_id).api_client
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
    message = e.message.truncate(150)
    logger.warn "#{self.class}: #{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.join "\n"

    raise Error, e unless async
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{twitter_user.screen_name}"
  end

  private

  class Error < StandardError
    def initialize(ex)
      super("#{ex.class} #{ex.message.truncate(100)}")
    end
  end
end
