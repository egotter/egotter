class TrendsController < ApplicationController
  include DownloadTrendTweetsRequestConcern

  before_action :set_trend, only: %i(show tweets media download_tweets)

  rescue_from ActiveRecord::RecordNotFound do |e|
    redirect_to trends_path(via: current_via('record_not_found'))
  end

  def index
    @trends = Trend.japan.latest_trends.top_10.map { |t| TrendDecorator.new(t) }
  end

  def show
    @trend = TrendDecorator.new(@trend)
    @tweets = @trend.imported_tweets
    @latest_tweets = @tweets.slice(0..2).select(&:user)
    @oldest_tweets = @tweets.slice(-3..-1).select(&:user)
  end

  def tweets
    @trend = TrendDecorator.new(@trend)
    @tweets = @trend.imported_tweets
    @latest_tweets = @tweets.slice(0..99).select(&:user)
    @oldest_tweets = @tweets.slice(-100..-1).select(&:user)
  end

  def media
    @trend = TrendDecorator.new(@trend)
    @tweets = MediaCache.new.fetch(@trend.id) do
      @trend.imported_tweets.
          map { |t| t.retweeted_status ? t.retweeted_status : t }.
          select(&:media_url).
          uniq!(&:tweet_id)
    end
  end

  # TODO Download from S3 directly
  def download_tweets
    data = data_for_download(@trend, @trend.imported_tweets.take(limit_for_download))
    render_for_download(@trend, data)
  end

  private

  def set_trend
    @trend = Trend.find(params[:id])
  end

  class MediaCache
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
          Hashie::Mash.new(tweet_url: attrs['tweet_url'], media_url: attrs['media_url'])
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
        Rails.logger.debug { "MediaCache: Read from cache trend_id=#{trend_id}" }
        result
      else
        result = yield
        write(trend_id, result)
        Rails.logger.debug { "MediaCache: Write to cache trend_id=#{trend_id}" }
        result
      end
    end

    def self.redis
      @redis ||= Redis.client(ENV['REDIS_HOST'], db: 4)
    end
  end
end
