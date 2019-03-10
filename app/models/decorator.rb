class Decorator
  extend Util::Memoization

  def initialize(users)
    @users = users
  end

  def decorate
    users = persisted_users.map {|user| to_hash(user)}
    Result.new(users)
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
    users =
        if @users.empty?
          []
        else
          TwitterDB::User.where(uid: @users.map(&:uid)).index_by(&:uid)
        end
    @users.map {|user| users[user.uid]}.compact
  end
  memoize

  def suspended_uids
    if remove_related_page?
      uids = @users.map(&:uid)
      t_uids = client.users(uids).map {|u| u[:id]}
      uids - t_uids
    else
      []
    end
  rescue Twitter::Error::Unauthorized => e
    unless e.message == 'Invalid or expired token.'
      logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect.truncate(100)}"
      logger.info e.backtrace.join("\n")
    end
  rescue Twitter::Error::NotFound => e
    unless e.message == 'No user matches for specified terms.'
      logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect.truncate(100)}"
      logger.info e.backtrace.join("\n")
    end
    []
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
    []
  end
  memoize

  def blocking_uids
    (remove_related_page? && user) ? client.blocked_ids : []
  rescue Twitter::Error::Unauthorized => e
    unless e.message == 'Invalid or expired token.'
      logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect.truncate(100)}"
      logger.info e.backtrace.join("\n")
    end
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
    []
  end
  memoize

  def friend_uids
    friend_related_page? ? (user&.twitter_user&.friend_uids || []) : []
  end
  memoize

  def follower_uids
    follower_related_page? ? (user&.twitter_user&.follower_uids || []) : []
  end
  memoize

  def friend_related_page?
    %w(unfriends blocking_or_blocked).include?(@controller_name)
  end
  memoize

  def follower_related_page?
    %w(unfollowers blocking_or_blocked).include?(@controller_name)
  end
  memoize

  def remove_related_page?
    %w(unfriends unfollowers blocking_or_blocked).include?(@controller_name)
  end
  memoize

  def user
    User.find_by(id: @user_id)
  end
  memoize

  def client
    user&.api_client || Bot.api_client
  end
  memoize

  def to_hash(user)
    {
        uid: user.uid.to_s,
        screen_name: user.screen_name,
        name: user.name,
        friends_count: user.friends_count,
        followers_count: user.followers_count,
        statuses_count: user.statuses_count,
        profile_image_url_https: user.profile_image_url_https.to_s,
        description: user.description,
        protected: user.protected,
        verified: user.verified,
        suspended: suspended_uids.include?(user.uid),
        blocked: blocking_uids.include?(user.uid),
        refollow: friend_uids.include?(user.uid),
        refollowed: follower_uids.include?(user.uid),
        inactive: user.inactive
    }
  end

  def logger
    Rails.logger
  end
end
