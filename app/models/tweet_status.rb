class TweetStatus

  class << self
    def no_status_found?(ex)
      ex.class == Twitter::Error::NotFound && ex.message == 'No status found with that ID.'
    end

    def that_page_does_not_exist?(ex)
      ex.class == Twitter::Error::NotFound && ex.message == 'Sorry, that page does not exist.'
    end

    def forbidden?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == 'Forbidden.'
    end

    def not_authorized?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == 'Sorry, you are not authorized to see this status.'
    end

    def you_have_been_blocked?(ex)
      ex.class == Twitter::Error::Unauthorized && ex.message == 'You have been blocked from the author of this tweet.'
    end

    def temporarily_locked?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == 'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
    end

    def already_favorited?(ex)
      ex.class == Twitter::Error::AlreadyFavorited
    end

    def duplicate_status?(ex)
      ex.class == Twitter::Error::DuplicateStatus
    end
  end
end
