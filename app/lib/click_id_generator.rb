class ClickIdGenerator

  ID_REGEXP = /\Ainvitation-\d{1,30}\z/

  class << self
    def gen(user)
      "invitation-#{user.uid}" if user
    end

    def valid?(id)
      id&.to_s&.match?(ID_REGEXP)
    end

    def invited_count(user)
      invited_user_ids(user).size
    end

    def invited_user_ids(user)
      regexp = "^invitation-#{user ? user.uid : '\\d+'}$"

      query = Ahoy::Event.select('distinct user_id').
          where('time > ?', 2.weeks.ago).
          where(name: 'Sign up').
          where("properties->>'$.click_id' regexp ?", regexp)

      if (min_user = User.select(:id).where('created_at > ?', 2.weeks.ago).order(created_at: :asc)[0])
        query = query.where('user_id >= ?', min_user.id)
      end

      query.map(&:user_id)
    end

    def invitation_bonus
      100
    end
  end
end
