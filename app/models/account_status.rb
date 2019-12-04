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

  def unauthorized?
    @ex && @ex.class == Twitter::Error::Unauthorized && @ex.message == 'Invalid or expired token.'
  end

  class << self
    def not_found?(ex)
      new(ex: ex).not_found?
    end

    def suspended?(ex)
      new(ex: ex).suspended?
    end

    def unauthorized?(ex)
      new(ex: ex).unauthorized?
    end
  end
end
