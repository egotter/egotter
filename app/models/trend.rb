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
  JAPAN_WOE_ID = 23424856

  class << self
    def save_current_trends
      Bot.api_client.twitter.trends(JAPAN_WOE_ID).each do |trend|
        create!(woe_id: JAPAN_WOE_ID, properties: trend, time: Time.zone.now)
      end
    end
  end
end
