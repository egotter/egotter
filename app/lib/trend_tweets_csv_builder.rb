require 'csv'

class TrendTweetsCsvBuilder
  def initialize(trend, tweets, with_description: false)
    @trend = trend
    @tweets = tweets
    @with_description = with_description
    @headers = %w(trend_time uid screen_name tweet_id tweet_time text)
  end

  def build
    CSV.generate(headers: @headers, write_headers: true, force_quotes: true) do |csv|
      @tweets.each do |tweet|
        csv << [@trend.time, tweet.uid, tweet.screen_name, tweet.tweet_id, tweet.tweeted_at, tweet.text]
      end

      if !@with_description && @tweets.size == Order::FREE_PLAN_TREND_TWEETS_LIMIT
        url = Rails.application.routes.url_helpers.pricing_url(via: "download_trend_tweets_#{@tweets.size}")
        csv << ['-1', I18n.t('download.data.trend_tweets_note1', count: @tweets.size, url: url)]
      end

      if @with_description && @tweets.size == Order::BASIC_PLAN_TREND_TWEETS_LIMIT
        url = Rails.application.routes.url_helpers.pricing_url(via: "download_trend_tweets_#{@tweets.size}")
        csv << ['-1', I18n.t('download.data.trend_tweets_note2', count: @tweets.size, url: url)]
      end
    end
  end
end
