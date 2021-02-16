class TrendDecorator < ApplicationDecorator
  delegate_all

  SEARCH_URL_BASE = 'https://twitter.com/search?q='

  def display_time_jst
    object.time.in_time_zone('Tokyo').strftime('%Y年%-m月%-d日 %-H時0分')
  end

  def tweet_users_count
    object.trend_insight.users_count.map(&:first).uniq.size
  end

  def tweets_count
    [object.tweet_volume || -1, object.tweets_size || -1].max
  end

  def delimited_tweet_users_count
    tweet_users_count&.to_s(:delimited)
  end

  def delimited_tweets_count
    tweets_count&.to_s(:delimited)
  end

  # TODO Remove later
  def search_url
    query = object.query
    query += " since:#{ApiClient::CONVERT_TIME_FORMAT.call(object.time - 1.day)}"
    query += " until:#{ApiClient::CONVERT_TIME_FORMAT.call(object.time)}"
    SEARCH_URL_BASE + query
  end

  def latest_tweet
    object.imported_tweets.last
  end

  def words_count_chart
    (object.trend_insight&.words_count || []).map { |w, c| {word: w, count: c} }
  end

  def times_count_chart(padding: true)
    insight = object.trend_insight
    times_count = insight&.times_count

    return [] if times_count.blank?

    if padding
      times_count.sort_by! { |t, _| t }

      oldest_time = Time.zone.at(times_count[0][0]).tap { |t| t.change(second: 0) }
      latest_time = Time.zone.at(times_count[-1][0]).tap { |t| t.change(second: 0) }

      10.times do
        times_count << [(oldest_time -= 1.minute).to_i, 0]
        times_count << [(latest_time += 1.minute).to_i, 0]
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
