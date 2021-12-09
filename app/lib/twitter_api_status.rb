class TwitterApiStatus

  class << self
    def not_found?(ex)
      ex && ex.class == Twitter::Error::NotFound && ex.message == 'User not found.'
    end

    def no_user_matches?(ex)
      ex && ex.class == Twitter::Error::NotFound && ex.message == 'No user matches for specified terms.'
    end

    def forbidden?(ex)
      ex && ex.class == Twitter::Error::Forbidden
    end

    def suspended?(ex)
      ex && ex.class == Twitter::Error::Forbidden && ex.message == 'User has been suspended.'
    end

    # This exception is raised when calling #user_timeline
    def blocked?(ex)
      ex && ex.class == Twitter::Error::Unauthorized && ex.message == "You have been blocked from viewing this user's profile."
    end

    # This exception is raised when calling #user_timeline
    # TODO Rename to not_authorized?
    def protected?(ex)
      ex && ex.class == Twitter::Error::Unauthorized && ex.message == "Not authorized."
    end

    def not_authorized?(ex)
      ex && ex.class == Twitter::Error::Unauthorized && ex.message == "Not authorized."
    end

    def unauthorized?(ex)
      invalid_or_expired_token?(ex) || bad_authentication_data?(ex) || _unauthorized?(ex)
    end

    def invalid_or_expired_token?(ex)
      ex && ex.class == Twitter::Error::Unauthorized && ex.message.include?('Invalid or expired token')
    end

    def could_not_authenticate_you?(ex)
      ex && ex.class == Twitter::Error::Unauthorized && ex.message == 'Could not authenticate you.'
    end

    def bad_authentication_data?(ex)
      ex && ex.class == Twitter::Error::BadRequest && ex.message == 'Bad Authentication data.'
    end

    def _unauthorized?(ex)
      ex && ex.class == Twitter::Error::Unauthorized && ex.message == ''
    end

    # TODO Rename to #rate_limit_exceeded?
    def too_many_requests?(ex)
      # Sometimes the 'Rate limit exceeded' message is not set
      ex && ex.class == Twitter::Error::TooManyRequests
    end

    def temporarily_locked?(ex)
      ex && ex.class == Twitter::Error::Forbidden && ex.message == 'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
    end

    def your_account_suspended?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == "Your account is suspended and is not permitted to access this feature."
    end

    # This exception is raised when calling #follow!
    def blocked_from_following?(ex)
      ex && ex.class == Twitter::Error::Forbidden && ex.message == 'You have been blocked from following this account at the request of the user.'
    end

    # This exception is raised when calling #follow!
    def unable_to_follow?(ex)
      ex && ex.class == Twitter::Error::Forbidden && ex.message == "You are unable to follow more people at this time. Learn more <a href='http://support.twitter.com/articles/66885-i-can-t-follow-people-follow-limits'>here</a>."
    end
  end
end
