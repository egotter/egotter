class SearchLimitation

  SOFT_LIMIT = Rails.configuration.x.constants['search_limitation']['soft_limit']
  HARD_LIMIT = Rails.configuration.x.constants['search_limitation']['hard_limit']

  class << self
    def too_many_friends?(user: nil, twitter_user: nil)
      Rails.logger.warn "Deprecated calling #too_many_friends?"
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

    def limited?(user, signed_in: false)
      signed_in ? hard_limited?(user) : soft_limited?(user)
    end

    def soft_limited?(user)
      user[:friends_count] + user[:followers_count] > SOFT_LIMIT
    end

    def hard_limited?(user)
      user[:friends_count] + user[:followers_count] > HARD_LIMIT
    end
  end
end
