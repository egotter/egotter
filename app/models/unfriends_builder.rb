class UnfriendsBuilder

  # TODO Decrease to avoid high loads
  DEFAULT_LIMIT = 100

  def initialize(uid, start_date: nil, end_date:, limit: DEFAULT_LIMIT)
    @users = Util.users(uid, start_date, end_date, limit: limit)

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

  def first_user
    @users.first
  end

  def last_user
    @users.last
  end

  def twitter_users
    @users
  end

  module Util
    module_function

    # Fetch users that are created before the specified date without limit
    # Separated for test
    def users(uid, start_date, end_date, limit: DEFAULT_LIMIT)
      query = TwitterUser.creation_completed.
          where('created_at <= ?', end_date).
          where(uid: uid)

      query = query.where('created_at >= ?', start_date) if start_date

      query.select(:id, :created_at).
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

    def unfollowers_increased?(older, newer)
      result = unfollowers(older, newer)
      !result.nil? && result.any?
    end
  end
end
