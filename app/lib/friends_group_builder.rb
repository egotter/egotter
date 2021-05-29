class FriendsGroupBuilder
  def initialize(uid, limit: nil, users: nil)
    if users.nil?
      @users = Util.users(uid, limit: limit)
    else
      @users = users
    end

    # @users is preloaded in the caller(UpdateAudienceInsightWorker)
  end

  def users
    @users
  end

  def friends
    @users.map(&:friend_uids)
  end

  def followers
    @users.map(&:follower_uids)
  end

  # New friends between old record and new record
  def new_friends
    @users.each_cons(2).map { |older, newer| Util.new_friends(older, newer) }.compact.tap { |ary| ary.prepend([]) if ary.empty? }
  end

  # New followers between old record and new record
  def new_followers
    @users.each_cons(2).map { |older, newer| Util.new_followers(older, newer) }.compact.tap { |ary| ary.prepend([]) if ary.empty? }
  end

  # Used by AudienceInsightChartBuilder
  # TODO Not enough implementation. Rename to new_unfriends
  def unfriends
    @users.each_cons(2).map { |older, newer| Util.unfriends(older, newer) }.compact.tap { |ary| ary.prepend([]) }
  end

  # Used by AudienceInsightChartBuilder
  # TODO Not enough implementation. Rename to new_unfollowers
  def unfollowers
    @users.each_cons(2).map { |older, newer| Util.unfollowers(older, newer) }.compact.tap { |ary| ary.prepend([]) }
  end

  def new_unfriends
    raise NotImplementedError
  end

  def new_unfollowers
    raise NotImplementedError
  end

  module Util
    module_function

    # Fetch users over an entire period with limit
    # Separated for test
    def users(uid, limit:)
      TwitterUser.creation_completed.
          where(uid: uid).
          select(:id, :uid, :screen_name, :created_at).
          order(created_at: :desc).
          limit(limit).
          reverse
    end

    def unfriends(older, newer)
      UnfriendsBuilder::Util.unfriends(older, newer)
    end

    def unfollowers(older, newer)
      UnfriendsBuilder::Util.unfollowers(older, newer)
    end

    # #new_unfriends and #new_unfollowers are not implemented because it's same as #unfriends and #unfollowers.

    def new_friends(older, newer)
      newer ? newer.friend_uids - older.friend_uids : nil
    end

    def new_followers(older, newer)
      newer ? newer.follower_uids - older.follower_uids : nil
    end
  end
end
