module PublicTweetsHelper
  def tweets_for(keyword)
    if Util::TweetsCache.exists?(keyword)
      JSON.parse(Util::TweetsCache.get(keyword)).map { |tweet| Hashie::Mash.new(tweet) }
    else
      CreateTweetsWorker.perform_async(keyword)
      []
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{keyword}"
    []
  end
end
