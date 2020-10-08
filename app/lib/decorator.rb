class Decorator
  extend Memoization

  def initialize(users)
    @users = users
  end

  def decorate
    [persisted_users, {suspended_uids: suspended_uids, blocking_uids: blocking_uids, friend_uids: friend_uids, follower_uids: follower_uids}]
  end

  def user_id(value)
    @user_id = value
    self
  end

  def controller_name(value)
    @controller_name = value
    self
  end

  class Result
    attr_reader :users

    def initialize(users)
      @users = users
    end
  end

  private

  def persisted_users
    return [] if @users.empty?
    TwitterDB::User.where_and_order_by_field(uids: @users.map(&:uid))
  end
  memoize

  def suspended_uids
    if remove_related_page?
      uids = @users.map(&:uid)
      uids - client.users(uids).map { |u| u[:id] }
    else
      []
    end
  rescue => e
    AccountStatus.no_user_matches?(e) ? @users.map(&:uid) : []
  end

  def blocking_uids
    (remove_related_page? && user) ? client.blocked_ids : []
  rescue => e
    []
  end

  def friend_uids
    friend_related_page? ? (user&.twitter_user&.friend_uids || []) : []
  end

  def follower_uids
    follower_related_page? ? (user&.twitter_user&.follower_uids || []) : []
  end

  def friend_related_page?
    %w(unfriends mutual_unfriends).include?(@controller_name)
  end

  def follower_related_page?
    %w(unfollowers mutual_unfriends).include?(@controller_name)
  end

  def remove_related_page?
    %w(unfriends unfollowers mutual_unfriends).include?(@controller_name)
  end

  def user
    User.where(authorized: true, locked: false).find_by(id: @user_id)
  end
  memoize

  def client
    user&.api_client || Bot.api_client
  end
  memoize

  def logger
    Rails.logger
  end
end
