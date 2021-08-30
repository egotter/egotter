class ClickIdGenerator

  ID_REGEXP = /\Ainvitation-\d{1,30}-\d{1,30}\z/

  class << self
    def gen(user)
      "invitation-#{Time.zone.now.to_i}-#{user.uid}" if user
    end

    def valid?(id)
      id&.to_s&.match?(ID_REGEXP)
    end
  end
end
