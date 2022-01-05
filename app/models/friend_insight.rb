# == Schema Information
#
# Table name: friend_insights
#
#  id              :bigint(8)        not null, primary key
#  uid             :bigint(8)        not null
#  profiles_count  :json
#  locations_count :json
#  tweet_times     :json
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_friend_insights_on_created_at  (created_at)
#  index_friend_insights_on_uid         (uid) UNIQUE
#
class FriendInsight < ApplicationRecord
  include FriendInsightsUtil

  class << self
    def builder(uid)
      Builder.new(uid)
    end
  end

  class Builder
    def initialize(uid)
      @uid = uid
    end

    def build
      twitter_user = TwitterUser.latest_by(uid: @uid)
      users = twitter_user.friends
      return if users.blank?

      insight = FriendInsight.find_or_initialize_by(uid: @uid)
      insight.profiles_count = calc_profiles_count(users)
      insight.locations_count = calc_locations_count(users)
      insight.tweet_times = users.map { |u| u.status_created_at&.utc&.to_i }.compact
      insight
    end

    private

    def calc_profiles_count(users)
      if (text = users.take(200).map(&:description).join(' ')).present?
        WordCloud.new.count_words(text)
      end
    end

    def calc_locations_count(users)
      if (text = users.take(5000).map(&:location).join(' ').upcase).present?
        WordCloud.new.count_words(text)
      end
    end
  end
end
