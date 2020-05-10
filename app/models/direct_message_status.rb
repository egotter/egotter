class DirectMessageStatus

  class << self
    def cannot_send_messages?(ex)
      you_have_blocked?(ex) ||
          not_following_you?(ex) ||
          do_not_follow_you?(ex) ||
          any_reason?(ex) ||
          might_be_automated?(ex) ||
          not_allowed_to_access_or_delete?(ex)
    end

    def you_have_blocked?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == 'You cannot send messages to users you have blocked.'
    end

    def not_following_you?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == 'You cannot send messages to users who are not following you.'
    end

    def do_not_follow_you?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == 'You are sending a Direct Message to users that do not follow you.'
    end

    def cannot_find_specified_user?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == 'Cannot find specified user.'
    end

    def any_reason?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == 'You cannot send messages to this user.'
    end

    def might_be_automated?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == "This request looks like it might be automated. To protect our users from spam and other malicious activity, we can't complete this action right now. Please try again later."
    end

    def protect_out_users_from_spam?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == "To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account."
    end

    # https://twittercommunity.com/t/updates-to-app-permissions-direct-message-write-permission-change/128221
    def not_allowed_to_access_or_delete?(ex)
      ex.class == Twitter::Error::Forbidden && ex.message == 'This application is not allowed to access or delete your direct messages.'
    end
  end
end
