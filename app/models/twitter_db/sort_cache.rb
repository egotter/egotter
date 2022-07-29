require 'singleton'
require 'digest/md5'

module TwitterDB
  class SortCache
    include Singleton

    def initialize
      @redis = RedisClient.new(host: ENV['SORT_CACHE_REDIS_HOST'], db: 2)
      @ttl = 300
    end

    def read(sort, uids)
      decompress(@redis.get(key(sort, uids)))
    end

    def write(sort, uids, ary)
      @redis.setex(key(sort, uids), @ttl, compress(ary))
    end

    def exists?(sort, uids)
      k = key(sort, uids)
      @redis.exists?(k) && @redis.ttl(k) > 3
    end

    # Not used
    def delete(sort, uids)
      @redis.del(key(sort, uids))
    end

    private

    def decompress(data)
      JSON.parse(Zlib::Inflate.inflate(Base64.decode64(data)))
    end

    def compress(ary)
      Base64.encode64(Zlib::Deflate.deflate(ary.to_json))
    end

    def key(sort, uids)
      "#{Rails.env}:sort_cache:#{sort}:#{Digest::MD5.hexdigest(uids.to_json)}"
    end
  end
end
