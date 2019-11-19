class SearchLimitation

  MANY_FRIENDS = Rails.configuration.x.constants['many_friends_threshold']
  TOO_MANY_FRIENDS = Rails.configuration.x.constants['too_many_friends_threshold']

  class << self
    def too_many_friends?(user: nil, twitter_user: nil)
      if user
        fetched_user = user.api_client.user
        if fetched_user[:friends_count] + fetched_user[:followers_count] > TOO_MANY_FRIENDS
          true
        else
          false
        end
      elsif twitter_user
        if twitter_user.friends_count + twitter_user.followers_count > TOO_MANY_FRIENDS
          true
        else
          false
        end
      else
        raise 'Specify user or twitter_user.'
      end
    end
  end
end
