class TrendDecorator < ApplicationDecorator
  delegate_all

  SEARCH_URL_BASE = 'https://twitter.com/search?q='

  def search_url
    query = object.query
    query += " since:#{ApiClient::CONVERT_TIME_FORMAT.call(object.time - 1.day)}"
    query += " until:#{ApiClient::CONVERT_TIME_FORMAT.call(object.time)}"
    SEARCH_URL_BASE + query
  end

  def tweets_count
    object.tweet_volume || object.tweets_size
  end

  def latest_tweet
    object.tweets.last
  end
end
