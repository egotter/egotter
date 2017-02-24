module StatusesHelper


  def tweets_for(keyword)
    cache = Util::TweetsCache.new(redis)
    if cache.exists?(keyword)
      JSON.parse(cache.get(keyword)).map { |tweet| Hashie::Mash.new(tweet) }
    else
      CreateTweetsWorker.perform_async(keyword)
      []
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{keyword}"
    []
  end
end
