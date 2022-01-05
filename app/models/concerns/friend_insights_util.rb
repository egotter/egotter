require 'active_support/concern'

module FriendInsightsUtil
  extend ActiveSupport::Concern

  def fresh?
    updated_at && updated_at > 30.minutes.ago
  end

  def sorted_profiles_count
    profiles_count.sort_by { |_, v| -v } rescue {}
  end

  def top_3_profile_words
    sorted_profiles_count.take(3).map(&:first) rescue []
  end

  def sorted_locations_count
    locations_count.sort_by { |_, v| -v } rescue {}
  end

  def top_3_location_words
    sorted_locations_count.take(3).map(&:first) rescue []
  end

  def parsed_tweet_times
    tweet_times.map { |t| Time.zone.at(t) } rescue []
  end

  def top_3_tweet_hours
    parsed_tweet_times.each_with_object(Hash.new(0)) { |t, m| m[t.hour] += 1 }.sort_by { |_, v| -v }.take(3).map(&:first) rescue []
  end
end
