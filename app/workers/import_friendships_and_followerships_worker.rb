class ImportFriendshipsAndFollowershipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id, uid)
    client = user_id == -1 ? Bot.api_client : User.find(user_id).api_client
    twitter_user = TwitterUser.latest(uid)

    signatures = [
      {method: :friends,   args: [uid]},
      {method: :followers, args: [uid]}
    ]

    friends = followers = []
    ActiveRecord::Base.benchmark("[benchmark] #{self.class}#fetch friends and followers") do
      friends, followers = client._fetch_parallelly(signatures)
    end

    ActiveRecord::Base.benchmark('[benchmark] import Friendship and Followership') { ActiveRecord::Base.transaction {
      Friendship.import_from!(twitter_user.id, friends.map(&:id)) if friends&.any?
      Followership.import_from!(twitter_user.id, followers.map(&:id)) if followers&.any?
    }}

    ActiveRecord::Base.benchmark('[benchmark] import Unfriendship') do
      Unfriendship.import_from!(uid, calc_removing_uids)
    end

    ActiveRecord::Base.benchmark('[benchmark] import Unfollowership') do
      Unfollowership.import_from!(uid, calc_removed_uids)
    end

    ActiveRecord::Base.benchmark('[benchmark] import OneSidedFriendship') do
      OneSidedFriendship.import_from!(uid, calc_one_sided_friend_uids)
    end

    ActiveRecord::Base.benchmark('[benchmark] import OneSidedFollowership') do
      OneSidedFollowership.import_from!(uid, calc_one_sided_follower_uids)
    end

    ActiveRecord::Base.benchmark('[benchmark] import MutualFriendship') do
      MutualFriendship.import_from!(uid, calc_mutual_friend_uids)
    end

    ActiveRecord::Base.benchmark('[benchmark] import InactiveFriendship') do
      InactiveFriendship.import_from!(uid, twitter_user.calc_inactive_friend_uids)
    end

    ActiveRecord::Base.benchmark('[benchmark] import InactiveFollowership') do
      InactiveFollowership.import_from!(uid, twitter_user.calc_inactive_follower_uids)
    end

    ActiveRecord::Base.benchmark('[benchmark] import InactiveMutualFriendship') do
      InactiveMutualFriendship.import_from!(uid, twitter_user.calc_inactive_mutual_friend_uids)
    end

    ImportFriendsAndFollowersWorker.perform_async(user_id, uid) if twitter_user.friendships.any? || twitter_user.followerships.any?

  rescue Twitter::Error::Unauthorized => e
    case e.message
      when 'Invalid or expired token.' then User.find_by(id: user_id)&.update(authorized: false)
      when 'Could not authenticate you.' then logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
      else logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
    end
  rescue ActiveRecord::StatementInvalid => e
    message = e.message.truncate(60)
    logger.warn "#{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.join "\n"
  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.join "\n"
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{twitter_user.screen_name}"
  end
end
