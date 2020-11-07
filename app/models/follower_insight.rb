# == Schema Information
#
# Table name: follower_insights
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
#  index_follower_insights_on_created_at  (created_at)
#  index_follower_insights_on_uid         (uid) UNIQUE
#
class FollowerInsight < ApplicationRecord
  def fresh?
    updated_at && updated_at > 30.minutes.ago
  end

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
      users = twitter_user.followers
      return if users.blank?

      insight = FollowerInsight.find_or_initialize_by(uid: @uid)
      insight.profiles_count = calc_profiles_count(users)
      insight.locations_count = calc_locations_count(users)
      insight.tweet_times = users.map { |u| u.status_created_at&.utc&.to_i }.compact
      insight
    end

    private

    def calc_profiles_count(users)
      text = users.take(200).map(&:description).join(' ')
      WordCloud.new.count_words(text)
    end

    def calc_locations_count(users)
      text = users.take(5000).map(&:location).join(' ').upcase
      WordCloud.new.count_words(text)
    end
  end
end
