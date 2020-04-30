class UnfriendsBuilder

  # TODO Decrease to avoid high loads
  DEFAULT_LIMIT = 100

  def initialize(twitter_user, limit: DEFAULT_LIMIT)
    @users = Util.users(twitter_user.uid, twitter_user.created_at, limit: limit)

    # Experimental preload
    Parallel.each(@users, in_threads: 10) do |user|
      user.friend_uids
      user.follower_uids
    end
  end

  # Format:
  #   [[1, 2, 3], [4, 5, 6], [7, 8, 9] ...]
  def unfriends
    @users.each_cons(2).map { |older, newer| Util.unfriends(older, newer) }.compact.reverse
  end

  # Format:
  #   [[1, 2, 3], [4, 5, 6], [7, 8, 9] ...]
  def unfollowers
    @users.each_cons(2).map { |older, newer| Util.unfollowers(older, newer) }.compact.reverse
  end

  module Util
    module_function

    # Fetch users that are created before the specified date without limit
    # Separated for test
    def users(uid, created_at, limit: DEFAULT_LIMIT)
      TwitterUser.creation_completed.
          where('created_at <= ?', created_at).
          where(uid: uid).
          select(:id, :created_at).
          order(created_at: :desc).
          limit(limit).
          reverse
    end

    def unfriends(older, newer)
      newer ? older.friend_uids - newer.friend_uids : nil
    end

    def unfollowers(older, newer)
      newer ? older.follower_uids - newer.follower_uids : nil
    end
  end
end
