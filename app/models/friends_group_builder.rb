class FriendsGroupBuilder
  def initialize(uid, limit:, preload: true)
    @users = Util.users(uid, limit: limit)

    if preload
      ApplicationRecord.benchmark("#{self.class}##{__method__} Preload s3 files #{uid} #{limit} #{@users.size}", level: :info) do
        S3::Friendship.where!(twitter_user_ids: @users.map(&:id))
        S3::Followership.where!(twitter_user_ids: @users.map(&:id))
      end
    end
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
    #This is a stub implementation.
  end

  # New followers between old record and new record
  def new_followers
    #This is a stub implementation.
  end

  # Used by AudienceInsightChartBuilder
  # TODO Not enough implementation. Rename to new_unfriends
  def unfriends
    #This is a stub implementation.
  end

  # Used by AudienceInsightChartBuilder
  # TODO Not enough implementation. Rename to new_unfollowers
  def unfollowers
    #This is a stub implementation.
  end

  def new_unfriends
    raise NotImplementedError
  end

  def new_unfollowers
    raise NotImplementedError
  end

  %i(new_friends new_followers unfriends unfollowers).each do |method_name|
    define_method(method_name) do
      @users.each_cons(2).map {|older, newer| Util.send(method_name, older, newer)}.compact.tap {|ary| ary.prepend([])}
    end
  end

  module Util
    module_function

    # Fetch users over an entire period with limit
    def users(uid, limit:)
      TwitterUser.creation_completed.
          where(uid: uid).
          select(:id, :uid, :created_at).
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
