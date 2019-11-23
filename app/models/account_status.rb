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

  class << self
    def not_found?(ex)
      new(ex: ex).not_found?
    end

    def suspended?(ex)
      new(ex: ex).suspended?
    end
  end
end
