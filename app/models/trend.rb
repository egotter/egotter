# == Schema Information
#
# Table name: trends
#
#  id                 :bigint(8)        not null, primary key
#  woe_id             :bigint(8)        not null
#  rank               :integer
#  tweet_volume       :integer
#  tweets_size        :integer
#  tweets_imported_at :datetime
#  name               :string(191)
#  properties         :json
#  time               :datetime         not null
#  words_count        :json
#  times_count        :json
#  created_at         :datetime         not null
#
# Indexes
#
#  index_trends_on_created_at  (created_at)
#  index_trends_on_time        (time)
#
class Trend < ApplicationRecord
  has_one :trend_insight

  # TODO Drop words_count
  # TODO Drop times_count

  WORLD_WOE_ID = 1
  JAPAN_WOE_ID = 23424856

  scope :world, -> { where(woe_id: WORLD_WOE_ID) }
  scope :japan, -> { where(woe_id: JAPAN_WOE_ID) }
  scope :top_n, -> (n) { where(rank: 1..n) }
  scope :top_10, -> { top_n(10) }

  #
  # tweet1 <- :since_id is tweet1.id
  # tweet2
  # tweet3 <- :max_id is tweet3.id - 1
  def search_tweets(count:, max_id: nil, since_id: nil, since: nil, _until: nil, client_loader: nil)
    time_format = '%Y-%m-%d_%H:%M:%S_UTC'
    options = {
        count: count,
        max_id: max_id,
        since_id: since_id,
        # since: (since || time - 1.day).strftime(time_format),
        # until: (_until || time).strftime(time_format),
        client_loader: client_loader,
    }
    TrendSearcher.new(name, options).search_tweets
  end

  def import_tweets(tweets)
    hash_tweets = tweets.map do |t|
      {uid: t.uid, screen_name: t.screen_name, raw_attrs_text: t.to_json}
    end

    S3::TrendTweet.import_from!(id, name, hash_tweets)
    update!(tweets_size: tweets.size, tweets_imported_at: Time.zone.now)
  end

  def update_trend_insight(tweets)
    unless (insight = trend_insight)
      insight = create_trend_insight
    end

    insight.update_words_count(tweets)
    insight.update_times_count(tweets)
    insight.update_users_count(tweets)
  end

  def tweets
    raise 'Trend#tweets is deprecated'
  end

  def imported_tweets
    @tweets ||= (S3::TrendTweet.find_by(id)&.tweets || [])
  end

  def query
    properties['query'] || URI.encode_www_form_component(name)
  end

  class << self
    def latest_trends
      where(time: last.time)
    end

    def build_from_response(trend, woe_id, rank, time)
      prop = {}

      # Don't include redundant values
      prop[:query] = trend.query unless URI.encode_www_form_component(trend.name) == trend.query
      prop[:promoted_content] = trend.promoted_content? if trend.promoted_content?

      # Without this line, nil will be converted to ()
      tweet_volume = trend.tweet_volume.nil? ? nil : trend.tweet_volume

      new(woe_id: woe_id, rank: rank, tweet_volume: tweet_volume, name: trend.name, properties: prop, time: time)
    end

    def fetch_trends(woe_ids = [WORLD_WOE_ID, JAPAN_WOE_ID])
      time = Time.zone.now.change(min: 0, sec: 0)
      client = User.admin.api_client.twitter

      woe_ids.map do |woe_id|
        client.trends(woe_id).map.with_index do |trend, i|
          build_from_response(trend, woe_id, i + 1, time)
        end
      end.flatten
    end

    GROUP_BY_HOUR_FORMAT = '%Y/%m/%d %H:00:00'

    def group_by_hour(tweets)
      tweets.map { |t| Time.zone.parse(t[:created_at]) }.sort_by { |t| t.to_i }.group_by { |t| t.strftime(GROUP_BY_HOUR_FORMAT) }.map { |k, v| [k, v.size] }.to_h
    end
  end
end
