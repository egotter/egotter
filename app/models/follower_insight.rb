# == Schema Information
#
# Table name: follower_insights
#
#  id              :bigint(8)        not null, primary key
#  uid             :bigint(8)        not null
#  profiles_count  :json
#  locations_count :json
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
      twitter_user = TwitterUser.select(:id, :created_at).latest_by(uid: @uid)
      users = twitter_user.followers
      return if users.blank?

      insight = FollowerInsight.find_or_initialize_by(uid: @uid)
      insight.profiles_count = calc_profiles_count(users)
      insight.locations_count = calc_locations_count(users)
      insight
    end

    private

    def calc_profiles_count(users)
      text = users.map(&:description).join(' ')
      UsageStat::WordCloud.new.count_words(text)
    end

    def calc_locations_count(users)
      text = users.map(&:location).join(' ').upcase
      UsageStat::WordCloud.new.count_words(text)
    end
  end
end
