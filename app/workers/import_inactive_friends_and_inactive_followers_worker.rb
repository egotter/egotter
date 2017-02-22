class ImportInactiveFriendsAndInactiveFollowersWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id, uid)
    twitter_user = TwitterUser.latest(uid)

    ActiveRecord::Base.benchmark('[benchmark] import InactiveFriendship') do
      InactiveFriendship.import_from!(uid, twitter_user.calc_inactive_friend_uids)
    end

    ActiveRecord::Base.benchmark('[benchmark] import InactiveFollowership') do
      InactiveFollowership.import_from!(uid, twitter_user.calc_inactive_follower_uids)
    end

    ActiveRecord::Base.benchmark('[benchmark] import InactiveMutualFriendship') do
      InactiveMutualFriendship.import_from!(uid, twitter_user.calc_inactive_mutual_friend_uids)
    end

    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{twitter_user.screen_name}"

  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{self.class}: #{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.join "\n"
  end
end
