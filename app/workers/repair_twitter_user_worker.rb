class RepairTwitterUserWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(twitter_user_id)
    twitter_user = TwitterUser.find(twitter_user_id)
    uid = twitter_user.uid.to_i
    user = User.where(authorized: true).find_by(id: twitter_user.user_id)
    client = user ? user.api_client : Bot.api_client

    if (twitter_user.friendships.empty? && twitter_user.friends_size > 0) || (twitter_user.followerships.empty? && twitter_user.followers_size > 0)
      if twitter_user.one? || twitter_user.latest?
        signatures = [{method: :user, args: [uid]}, {method: :friend_ids, args: [uid]}, {method: :follower_ids, args: [uid]}]
        t_user, friend_uids, follower_uids = client._fetch_parallelly(signatures)

        _transaction('import Friendship and Followership') do
          twitter_user.update!(user_info: t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, friends_size: friend_uids.size, followers_size: follower_uids.size)
          Friendship.import_from!(twitter_user.id, friend_uids)
          Followership.import_from!(twitter_user.id, follower_uids)
        end

        calc_friendships(twitter_user)
      else
        _transaction('import Friendship and Followership') do
          twitter_user.update!(friends_size: 0, followers_size: 0)
          Friendship.import_from!(twitter_user.id, [])
          Followership.import_from!(twitter_user.id, [])
        end

        _benchmark('import Unfriendship') { Unfriendship.import_from!(uid, TwitterUser.calc_removing_uids(uid)) }
        _benchmark('import Unfollowership') { Unfollowership.import_from!(uid, TwitterUser.calc_removed_uids(uid)) }
      end
    end

  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      User.find_by(id: twitter_user.user_id)&.update(authorized: false)
    else
      raise
    end
  end

  private

  def calc_friendships(twitter_user)
    uid = twitter_user.uid.to_i

    _benchmark('import Unfriendship') { Unfriendship.import_from!(uid, TwitterUser.calc_removing_uids(uid)) }
    _benchmark('import Unfollowership') { Unfollowership.import_from!(uid, TwitterUser.calc_removed_uids(uid)) }

    _benchmark('import OneSidedFriendship') { OneSidedFriendship.import_from!(uid, twitter_user.calc_one_sided_friend_uids) }
    _benchmark('import OneSidedFollowership') { OneSidedFollowership.import_from!(uid, twitter_user.calc_one_sided_follower_uids) }
    _benchmark('import MutualFriendship') { MutualFriendship.import_from!(uid, twitter_user.calc_mutual_friend_uids) }
  end
end
