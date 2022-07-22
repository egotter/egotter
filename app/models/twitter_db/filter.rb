module TwitterDB
  class Filter
    VALUES = [
        'active',
        "inactive_2weeks",
        "inactive_1month",
        "inactive_3months",
        "inactive_6months",
        "inactive_1year",
        "protected",
        "verified",
        "friends_>_followers",
        "followers_>_friends",
        "investor",
        "engineer",
        "designer",
        "bikini_model",
        "fashion_model",
        "pop_idol",
        "too_emotional",
        "has_instagram",
        "has_tiktok",
        "has_secret_account",
        "adult_account",
    ]

    def initialize(value)
      if value.present?
        @values = value.split(',').select { |v| VALUES.include?(v) }.map do |v|
          case v
          when 'active' then 'active_2weeks'
          when 'protected' then 'protected_account'
          when 'verified' then 'verified_account'
          when 'friends_>_followers' then 'has_more_friends'
          when 'followers_>_friends' then 'has_more_followers'
          when 'has_secret_account' then 'secret_account'
          else v
          end
        end
      else
        @values = []
      end
    end

    def any?
      @values.any?
    end

    def apply(query)
      @values.each { |value| query = query.send(value) }
      query
    end
  end
end
