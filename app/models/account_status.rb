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

  def blocked?
    @ex && @ex.class == Twitter::Error::Unauthorized && @ex.message == "You have been blocked from viewing this user's profile."
  end

  def unauthorized?
    invalid_or_expired_token? || bad_authentication_data?
  end

  def invalid_or_expired_token?
    @ex && @ex.class == Twitter::Error::Unauthorized && @ex.message == 'Invalid or expired token.'
  end

  def bad_authentication_data?
    @ex && @ex.class == Twitter::Error::BadRequest && @ex.message == 'Bad Authentication data.'
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
  end
end
