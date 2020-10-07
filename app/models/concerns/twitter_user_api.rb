require 'active_support/concern'

module TwitterUserApi
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
  end

  def one_sided_friends_rate
    # Use #friends_count instead of #friend_uids.size to reduce calls to the external API
    (one_sided_friendships.size.to_f / friends_count) rescue 0.0
  end

  def one_sided_followers_rate
    # Use #followers_count instead of #follower_uids.size to reduce calls to the external API
    (one_sided_followerships.size.to_f / followers_count) rescue 0.0
  end

  def mutual_friends_rate
    (mutual_friendships.size.to_f / (friend_uids | follower_uids).size) rescue 0.0
  end

  def status_interval_avg
    tweets = status_tweets.map { |t| t.tweeted_at.to_i }.sort_by { |t| -t }.take(100)
    tweets = tweets.slice(0, tweets.size - 1) if tweets.size.odd?
    return 0.0 if tweets.empty?
    times = tweets.each_slice(2).map { |t1, t2| t1 - t2 }
    times.sum / times.size
  rescue
    0.0
  end

  def follow_back_rate
    numerator = mutual_friendships.size
    # Use #followers_count instead of #follower_uids.size to reduce calls to the external API
    denominator = followers_count
    (numerator == 0 || denominator == 0) ? 0.0 : numerator.to_f / denominator
  rescue
    0.0
  end

  def reverse_follow_back_rate
    numerator = mutual_friendships.size
    # Use #friends_count instead of #friend_uids.size to reduce calls to the external API
    denominator = friends_count
    (numerator == 0 || denominator == 0) ? 0.0 : numerator.to_f / denominator
  rescue
    0.0
  end
end
