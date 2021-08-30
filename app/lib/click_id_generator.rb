class ClickIdGenerator

  ID_REGEXP = /\Ainvitation-\d{1,30}-\d{1,30}\z/

  class << self
    def gen(user)
      "invitation-#{Time.zone.now.to_i}-#{user.uid}" if user
    end

    def valid?(id)
      id&.to_s&.match?(ID_REGEXP)
    end

    def count(user)
      Ahoy::Event.select('count(distinct user_id) cnt').
          where('time > ?', 1.month.ago).
          where(user_id: user.id).
          where(name: 'Sign up').
          where("properties->'$.click_id' is not null")[0].
          cnt
    end
  end
end
