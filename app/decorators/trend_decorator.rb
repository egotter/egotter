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

  def words_count_chart
    (words_count || []).map { |w, c| {word: w, count: c} }
  end

  def times_count_chart(padding: true)
    return [] if times_count.blank?

    trend_time = object.time

    if padding
      time = trend_time - 1.day

      while time < trend_time do
        label_time = time.change(second: 0)
        if times_count.none? { |t, _| t == label_time.to_i }
          times_count << [label_time.to_i, 0]
        end
        time += 1.minute
      end
    end

    times_count.sort_by { |t, _| t }.map { |t, c| [t * 1000, c] }
  end
end
