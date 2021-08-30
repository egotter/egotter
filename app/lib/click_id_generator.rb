class ClickIdGenerator

  ID_REGEXP = /\Ainvitation-\d{1,30}-\d{1,30}\z/

  class << self
    def gen(user)
      "invitation-#{Time.zone.now.to_i}-#{user.uid}" if user
    end

    def valid?(id)
      id&.to_s&.match?(ID_REGEXP)
    end

    def invited_count(user)
      invited_user_ids(user).size
    end

    def invited_user_ids(user)
      regexp = "^invitation-\\d+-#{user ? user.uid : '\\d+'}$"
      Ahoy::Event.select('distinct user_id').
          where('time > ?', 2.weeks.ago).
          where(name: 'Sign up').
          where("properties->>'$.click_id' regexp ?", regexp).
          map(&:user_id)
    end

    def invitation_bonus
      100
    end
  end
end
