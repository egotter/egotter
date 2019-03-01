module Util
  class CreateCacheRequests < OriginalSortedSet
    def self.key
      @@key ||= 'create_cache:uids'
    end

    def self.ttl
      @@ttl ||= (Rails.env.production? ? 1.hour : 10.minutes)
    end
  end
end
