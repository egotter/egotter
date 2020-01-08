class SearchLimitation

  SOFT_LIMIT = Rails.configuration.x.constants['search_limitation']['soft_limit']
  HARD_LIMIT = Rails.configuration.x.constants['search_limitation']['hard_limit']

  class << self
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
