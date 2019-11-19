class TemporaryDmLimitation

  class << self
    def temporarily_locked?(ex)
      if ex.class == Twitter::Error::Forbidden
        ex.message == 'You cannot send messages to users you have blocked.' ||
            ex.message == 'You cannot send messages to users who are not following you.' ||
            ex.message == 'You are sending a Direct Message to users that do not follow you.' ||
            ex.message == 'You cannot send messages to this user.' ||
            ex.message == "This request looks like it might be automated. To protect our users from spam and other malicious activity, we can't complete this action right now. Please try again later."
      end
    end

    def you_have_blocked?(ex)
      ex.class == Twitter::Error::Forbidden &&
          ex.message == 'You cannot send messages to users you have blocked.'
    end

    # https://twittercommunity.com/t/updates-to-app-permissions-direct-message-write-permission-change/128221
    def not_allowed_to_access_or_delete_dm?(ex)
      if ex.class == Twitter::Error::Forbidden &&
          ex.message == 'This application is not allowed to access or delete your direct messages.'
      end
    end
  end
end
