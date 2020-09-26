class TweetStatus

  class << self
    def no_status_found?(ex)
      ex.class == Twitter::Error::NotFound && ex.message == 'No status found with that ID.'
    end

    def that_page_does_not_exist?(ex)
      ex.class == Twitter::Error::NotFound && ex.message == 'Sorry, that page does not exist.'
    end

    def not_authorized?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == 'Sorry, you are not authorized to see this status.'
    end
  end
end
