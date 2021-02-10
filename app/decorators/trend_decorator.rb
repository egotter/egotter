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
    object.imported_tweets.last
  end

  def tweet_users_count
    object.trend_insight.users_count.map(&:first).uniq.size
  end

  def words_count_chart
    (object.trend_insight.words_count || []).map { |w, c| {word: w, count: c} }
  end

  def times_count_chart(padding: true)
    insight = object.trend_insight
    times_count = insight.times_count

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

  def users_count_chart
    insight = object.trend_insight
    aggregated_values = insight.users_count

    return [] if aggregated_values.blank?

    result = aggregated_values.sort_by { |_, c| -c }.map { |v, c| [v, c] }.take(50).reverse
    users = TwitterDB::User.where(uid: result.map(&:first)).select(:uid, :screen_name).index_by(&:uid)

    result.map do |v, c|
      user = users[v]
      user ? [user.screen_name, c] : nil
    end.compact
  end
end
