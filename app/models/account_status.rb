class AccountStatus

  class << self
    def not_found?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::NotFound && ex.message == 'User not found.'
    end

    def no_user_matches?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::NotFound && ex.message == 'No user matches for specified terms.'
    end

    def forbidden?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::Forbidden
    end

    def suspended?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::Forbidden && ex.message == 'User has been suspended.'
    end

    # This exception is raised when calling #user_timeline
    def blocked?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::Unauthorized && ex.message == "You have been blocked from viewing this user's profile."
    end

    # This exception is raised when calling #user_timeline
    def protected?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::Unauthorized && ex.message == "Not authorized."
    end
    alias_method :not_authorized?, :protected?

    def unauthorized?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      invalid_or_expired_token?(ex) || bad_authentication_data?(ex)
    end

    def invalid_or_expired_token?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::Unauthorized && ex.message == 'Invalid or expired token'
    end

    def could_not_authenticate_you?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::Unauthorized && ex.message == 'Could not authenticate you.'
    end

    def bad_authentication_data?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::BadRequest && ex.message == 'Bad Authentication data.'
    end

    def too_many_requests?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      # Sometimes the 'Rate limit exceeded' message is not set
      ex && ex.class == Twitter::Error::TooManyRequests
    end

    def temporarily_locked?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::Forbidden && ex.message == 'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
    end

    def your_account_suspended?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex.class == Twitter::Error::Forbidden && ex.message == "Your account is suspended and is not permitted to access this feature."
    end

    # This exception is raised when calling #follow!
    def blocked_from_following?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::Forbidden && ex.message == 'You have been blocked from following this account at the request of the user.'
    end

    # This exception is raised when calling #follow!
    def unable_to_follow?(ex)
      Rails.logger.warn "#{self}##{__method__} is deprecated"
      ex && ex.class == Twitter::Error::Forbidden && ex.message == "You are unable to follow more people at this time. Learn more <a href='http://support.twitter.com/articles/66885-i-can-t-follow-people-follow-limits'>here</a>."
    end
  end

  class Cache
    def initialize
      @store = ActiveSupport::Cache::RedisCacheStore.new(
          namespace: "#{Rails.env}:account_status",
          expires_in: 3.minutes,
          redis: RedisClient.new
      )
    end

    def exists?(screen_name)
      @store.exist?(screen_name)
    end

    def read(screen_name)
      @store.read(screen_name)
    end

    def write(screen_name, status, uid, is_follower)
      @store.write(screen_name, status)
      @store.write("#{screen_name}:uid", uid) if uid
      @store.write("#{screen_name}:is_follower", is_follower)
    end

    def invalid?(screen_name)
      @store.read(screen_name) == 'invalid'
    end

    def not_found?(screen_name)
      @store.read(screen_name) == 'not_found'
    end

    def suspended?(screen_name)
      @store.read(screen_name) == 'suspended'
    end

    def blocked?(screen_name)
      @store.read(screen_name) == 'blocked'
    end

    def error?(screen_name)
      @store.read(screen_name).start_with?('error:')
    end

    def locked?(screen_name)
      @store.read(screen_name) == 'locked'
    end

    def protected?(screen_name)
      @store.read(screen_name) == 'protected'
    end

    def ok?(screen_name)
      @store.read(screen_name) == 'ok'
    end

    def uid(screen_name)
      @store.read("#{screen_name}:uid")&.to_i
    end

    def is_follower?(screen_name)
      @store.read("#{screen_name}:is_follower")
    end
  end
end
