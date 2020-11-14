# == Schema Information
#
# Table name: trends
#
#  id           :bigint(8)        not null, primary key
#  woe_id       :bigint(8)        not null
#  rank         :integer
#  tweet_volume :integer
#  name         :string(191)
#  properties   :json
#  time         :datetime         not null
#  created_at   :datetime         not null
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

  def search_tweets(options = {})
    self.class.search_tweets(name, options)
  end

  class << self
    def latest_trends
      where(time: last.time)
    end

    def save_current_trends
      time = Time.zone.now.change(min: 0, sec: 0)

      [WORLD_WOE_ID, JAPAN_WOE_ID].each do |woe_id|
        User.admin.api_client.twitter.trends(woe_id).each.with_index do |trend, i|
          prop = {query: trend.query}
          prop[:promoted_content] = true if trend.promoted_content?
          create!(woe_id: woe_id, rank: i + 1, tweet_volume: trend.tweet_volume, name: trend.name, properties: prop, time: time)
        end
      end
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
        tweets.empty? ? break : (max_id = tweets.last[:id])
      end

      collection
    end

    GROUP_BY_HOUR_FORMAT = '%Y/%m/%d %H:00:00'

    def group_by_hour(tweets)
      tweets.map { |t| Time.zone.parse(t[:created_at]) }.sort_by { |t| t.to_i }.group_by { |t| t.strftime(GROUP_BY_HOUR_FORMAT) }.map { |k, v| [k, v.size] }.to_h
    end
  end
end
