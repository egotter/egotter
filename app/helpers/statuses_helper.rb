module StatusesHelper
  def tweets_for(keyword)
    key = "tweets_cache_for:#{keyword}"
    json = redis.fetch(key, ttl: 1.day) do
      client.search(keyword).take(5).to_json
    end
    JSON.load(json).map { |s| Hashie::Mash.new(s) }
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{keyword}"
    []
  end
end
