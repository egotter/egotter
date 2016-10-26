module Util
  class UidList
    attr_reader :redis

    def initialize(redis)
      @redis = redis
    end

    def self.key
      raise NotImplementedError
    end

    def key
      self.class.key
    end

    def self.ttl
      raise NotImplementedError
    end

    def ttl
      self.class.ttl
    end

    def clear
      redis.del(key)
    end

    def cleanup
      redis.zremrangebyscore(key, 0, Time.zone.now.to_i - ttl)
    end

    def exists?(uid)
      cleanup
      redis.zrank(key, uid.to_s).present?
    end

    def add(uid)
      cleanup
      redis.zadd(key, Time.zone.now.to_i, uid.to_s)
    end

    def delete(uid)
      redis.zrem(key, uid.to_s)
    end

    def to_a
      cleanup
      redis.zrangebyscore(key, 0, Time.zone.now.to_i)
    end

    def size
      to_a.size
    end
  end

  class SearchedUidList < UidList
    def self.key
      @@key ||= 'background_search_worker:searched_uids'
    end

    def self.ttl
      @@ttl ||= Rails.configuration.x.constants['recently_searched']
    end
  end

  class UnauthorizedUidList < UidList
    def self.key
      @@key ||= 'background_update_worker:unauthorized'
    end

    def self.ttl
      @@ttl ||= 10.years.to_i
    end
  end

  class TooManyFriendsUidList < UidList
    def self.key
      @@key ||= 'background_update_worker:too_many_friends'
    end

    def self.ttl
      @@ttl ||= 10.years.to_i
    end
  end
end
