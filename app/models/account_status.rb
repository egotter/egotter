class AccountStatus
  def initialize(ex: nil)
    @ex = ex
  end

  def not_found?
    @ex && @ex.class == Twitter::Error::NotFound && @ex.message == 'User not found.'
  end

  def suspended?
    @ex && @ex.class == Twitter::Error::Forbidden && @ex.message == 'User has been suspended.'
  end

  # This exception is raised when calling #user_timeline .
  def blocked?
    @ex && @ex.class == Twitter::Error::Unauthorized && @ex.message == "You have been blocked from viewing this user's profile."
  end

  # This exception is raised when calling #user_timeline .
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
    @ex && @ex.class == Twitter::Error::Forbidden && @ex.message.start_with?('To protect our users from spam and other malicious activity, this account is temporarily locked.')
  end

  class << self
    def not_found?(ex)
      new(ex: ex).not_found?
    end

    def suspended?(ex)
      new(ex: ex).suspended?
    end

    def blocked?(ex)
      new(ex: ex).blocked?
    end

    def unauthorized?(ex)
      new(ex: ex).unauthorized?
    end

    def too_many_requests?(ex)
      new(ex: ex).too_many_requests?
    end

    def temporarily_locked?(ex)
      new(ex: ex).temporarily_locked?
    end
  end
end
