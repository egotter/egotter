module Util
  class TooManyFriendsUidList < UidList
    def self.key
      @@key ||= 'background_update_worker:too_many_friends'
    end

    def self.ttl
      @@ttl ||= 10.years.to_i
    end
  end
end