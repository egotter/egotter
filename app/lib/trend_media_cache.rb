class TrendMediaCache
  def initialize
    @store = ActiveSupport::Cache::RedisCacheStore.new(
        namespace: "#{Rails.env}:#{self.class}",
        expires_in: 30.minutes,
        race_condition_ttl: 5.minutes,
        redis: self.class.redis
    )

  end

  def read(trend_id)
    if (data = @store.read(trend_id))
      JSON.parse(data).map do |attrs|
        Tweet.new(attrs['tweet_url'], attrs['media_url'])
      end
    end
  end

  def write(trend_id, tweets)
    data = tweets.map do |tweet|
      {tweet_ur: tweet.tweet_url, media_url: tweet.media_url}
    end.to_json
    @store.write(trend_id, data)
  end

  def fetch(trend_id, &block)
    if (result = read(trend_id))
      Rails.logger.debug { "TrendMediaCache: Read from cache trend_id=#{trend_id}" }
      result
    else
      result = yield
      write(trend_id, result)
      Rails.logger.debug { "TrendMediaCache: Write to cache trend_id=#{trend_id}" }
      result
    end
  end

  def self.redis
    @redis ||= Redis.client(ENV['REDIS_HOST'], db: 4)
  end

  class Tweet
    attr_reader :tweet_url, :media_url

    def initialize(tweet_url, media_url)
      @tweet_url = tweet_url
      @media_url = media_url
    end
  end
end
