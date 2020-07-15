# == Schema Information
#
# Table name: trends
#
#  id         :bigint(8)        not null, primary key
#  woe_id     :bigint(8)        not null
#  properties :json
#  time       :datetime         not null
#
# Indexes
#
#  index_trends_on_time  (time)
#
class Trend < ApplicationRecord
  WORLD_WOE_ID = 1
  JAPAN_WOE_ID = 23424856

  class << self
    def save_current_trends
      time = Time.zone.now.change(min: 0, sec: 0)

      [WORLD_WOE_ID, JAPAN_WOE_ID].each do |woe_id|
        Bot.api_client.twitter.trends(woe_id).each do |trend|
          create!(woe_id: JAPAN_WOE_ID, properties: trend, time: time)
        end
      end
    end
  end
end
