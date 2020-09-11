class TweetStatus

  class << self
    def no_status_found?(ex)
      ex.class == Twitter::Error::NotFound && ex.message == 'No status found with that ID.'
    end
  end
end
