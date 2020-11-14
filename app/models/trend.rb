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
#  created_at         :datetime         not null
#
# Indexes
#
#  index_trends_on_created_at  (created_at)
#  index_trends_on_time        (time)
#
class Trend < ApplicationRecord
  WORLD_WOE_ID = 1
  JAPAN_WOE_ID = 23424856

  scope :world, -> { where(woe_id: WORLD_WOE_ID) }
  scope :japan, -> { where(woe_id: JAPAN_WOE_ID) }
  scope :top_n, -> (n) { where(rank: 1..n) }

  def search_tweets(options = {})
    self.class.search_tweets(name, options)
  end

  def import_tweets(tweets)
    tweets = tweets.map do |t|
      {uid: t.uid, screen_name: t.screen_name, raw_attrs_text: t.to_json}
    end
    S3::TrendTweet.import_from!(id, name, tweets)
  end

  def tweets
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

    def search_tweets(query, options = {})
      options[:count] = 10000 unless options[:count]
      options[:since] = 1.day.ago unless options[:since]
      options[:until] = Time.zone.now unless options[:until]

      collection = []
      max_id = nil
      count = options[:count]

      while collection.size < count
        tweets = Bot.api_client.search(query, options.merge(count: 100, max_id: max_id))
        collection.concat(tweets)
        break if tweets.empty? || max_id == tweets.last[:id]
        max_id = tweets.last[:id]
      end

      collection.map { |c| omit_unnecessary_data(c) }
    end

    def omit_unnecessary_data(tweet)
      data = Tweet.new(tweet)

      if tweet[:retweeted_status]
        data.retweeted_status = Tweet.new(tweet[:retweeted_status])
      end

      data
    end

    class Tweet
      attr_reader :id, :text, :uid, :screen_name, :created_at
      attr_accessor :retweeted_status

      def initialize(attrs)
        @id = attrs[:id]
        @text = attrs[:text]
        @uid = attrs[:user][:id]
        @screen_name = attrs[:user][:screen_name]
        @created_at = attrs[:created_at]
        @retweeted_status = nil
      end

      def to_json
        {
            id: @id,
            text: @text,
            uid: @uid,
            screen_name: @screen_name,
            created_at: @created_at,
            retweeted_status: @retweeted_status,
        }.to_json
      end
    end

    GROUP_BY_HOUR_FORMAT = '%Y/%m/%d %H:00:00'

    def group_by_hour(tweets)
      tweets.map { |t| Time.zone.parse(t[:created_at]) }.sort_by { |t| t.to_i }.group_by { |t| t.strftime(GROUP_BY_HOUR_FORMAT) }.map { |k, v| [k, v.size] }.to_h
    end
  end
end
