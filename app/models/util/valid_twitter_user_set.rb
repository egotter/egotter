module Util
  class ValidTwitterUserSet < TwitterUserSet
    def self.key
      @@key ||= 'valid_twitter_user'
    end

    def self.ttl
      @@ttl ||= 10.minutes.to_i
    end
  end
end