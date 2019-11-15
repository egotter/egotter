class UnfriendsBuilder
  def initialize(twitter_user, preload: true)
    @users = Util.users(twitter_user.uid, twitter_user.created_at)

    # if preload
    #   S3::Friendship.where(twitter_user_ids: @users.map(&:id))
    #   S3::Followership.where(twitter_user_ids: @users.map(&:id))
    # end
  end

  def unfriends
    @users.each_cons(2).map {|older, newer| Util.unfriends(older, newer)}.compact.reverse
  end

  def unfollowers
    @users.each_cons(2).map {|older, newer| Util.unfollowers(older, newer)}.compact.reverse
  end

  module Util
    module_function

    # Fetch users that are created before the specified date without limit
    def users(uid, created_at)
      TwitterUser.creation_completed.
          where('created_at <= ?', created_at).
          where(uid: uid).select(:id).
          order(created_at: :asc)
    end

    def unfriends(older, newer)
      newer ? older.friend_uids - newer.friend_uids : nil
    end

    def unfollowers(older, newer)
      newer ? older.follower_uids - newer.follower_uids : nil
    end
  end
end
