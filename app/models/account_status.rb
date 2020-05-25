class AccountStatus
  def initialize(ex: nil)
    @ex = ex
  end

  def exception
    @ex
  end

  def not_found?
    @ex && @ex.class == Twitter::Error::NotFound && @ex.message == 'User not found.'
  end

  def no_user_matches?
    @ex && @ex.class == Twitter::Error::NotFound && @ex.message == 'No user matches for specified terms.'
  end

  def forbidden?
    @ex && @ex.class == Twitter::Error::Forbidden
  end

  def suspended?
    @ex && @ex.class == Twitter::Error::Forbidden && @ex.message == 'User has been suspended.'
  end

  # This exception is raised when calling #user_timeline
  def blocked?
    @ex && @ex.class == Twitter::Error::Unauthorized && @ex.message == "You have been blocked from viewing this user's profile."
  end

  # This exception is raised when calling #follow!
  def blocked_from_following?
    @ex && @ex.class == Twitter::Error::Forbidden && @ex.message == 'You have been blocked from following this account at the request of the user.'
  end

  # This exception is raised when calling #follow!
  def unable_to_follow?
    @ex && @ex.class == Twitter::Error::Forbidden && @ex.message == "You are unable to follow more people at this time. Learn more <a href='http://support.twitter.com/articles/66885-i-can-t-follow-people-follow-limits'>here</a>."
  end

  # This exception is raised when calling #user_timeline
  def protected?
    @ex && @ex.class == Twitter::Error::Unauthorized && @ex.message == "Not authorized."
  end
  alias_method :not_authorized?, :protected?

  def unauthorized?
    invalid_or_expired_token? || bad_authentication_data?
  end

  def invalid_or_expired_token?
    @ex && @ex.class == Twitter::Error::Unauthorized && @ex.message == 'Invalid or expired token.'
  end

  def bad_authentication_data?
    @ex && @ex.class == Twitter::Error::BadRequest && @ex.message == 'Bad Authentication data.'
  end

  def too_many_requests?
    @ex && @ex.class == Twitter::Error::TooManyRequests && @ex.message == 'Rate limit exceeded'
  end

  def temporarily_locked?
    @ex && @ex.class == Twitter::Error::Forbidden && @ex.message == 'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
  end

  def your_account_suspended?
    @ex.class == Twitter::Error::Forbidden && @ex.message == "Your account is suspended and is not permitted to access this feature."
  end

  class << self
    def not_found?(ex)
      new(ex: ex).not_found?
    end

    def no_user_matches?(ex)
      new(ex: ex).no_user_matches?
    end

    def forbidden?(ex)
      new(ex: ex).forbidden?
    end

    def suspended?(ex)
      new(ex: ex).suspended?
    end

    def blocked?(ex)
      new(ex: ex).blocked?
    end

    def protected?(ex)
      new(ex: ex).protected?
    end
    alias_method :not_authorized?, :protected?

    def unauthorized?(ex)
      new(ex: ex).unauthorized?
    end

    def invalid_or_expired_token?(ex)
      new(ex: ex).invalid_or_expired_token?
    end

    def too_many_requests?(ex)
      new(ex: ex).too_many_requests?
    end

    def temporarily_locked?(ex)
      new(ex: ex).temporarily_locked?
    end

    def your_account_suspended?(ex)
      new(ex: ex).your_account_suspended?
    end

    def blocked_from_following?(ex)
      new(ex: ex).blocked_from_following?
    end

    def unable_to_follow?(ex)
      new(ex: ex).unable_to_follow?
    end
  end
end
