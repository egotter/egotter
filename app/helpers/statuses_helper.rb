module StatusesHelper

  TTL = Rails.env.development? ? 1.minute : 1.day

  def tweets_for(keyword)
    key = "tweets_cache_for:#{keyword}"
    if redis.exists(key)
      JSON.parse(redis.get(key)).map { |tweet| Hashie::Mash.new(tweet) }
    else
      CreateTweetsWorker.perform_async(keyword, TTL)
      []
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{keyword}"
    []
  end
end
