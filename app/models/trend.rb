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
#
# Indexes
#
#  index_trends_on_time  (time)
#
class Trend < ApplicationRecord
  WORLD_WOE_ID = 1
  JAPAN_WOE_ID = 23424856

  scope :world, -> { where(woe_id: WORLD_WOE_ID) }
  scope :japan, -> { where(woe_id: JAPAN_WOE_ID) }

  class << self
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
  end
end
