require 'active_support/concern'

module TwitterUserTweetAssociations
  extend ActiveSupport::Concern

  def status_tweets
    fetch_tweets(InMemory::StatusTweet, Efs::StatusTweet, S3::StatusTweet)
  end

  def favorite_tweets
    fetch_tweets(InMemory::FavoriteTweet, Efs::FavoriteTweet, S3::FavoriteTweet)
  end

  def mention_tweets
    fetch_tweets(InMemory::MentionTweet, Efs::MentionTweet, S3::MentionTweet)
  end

  private

  def fetch_tweets(memory_class, efs_class, s3_class)
    wrapper = nil
    start = Time.zone.now

    wrapper = memory_class.find_by(uid) if InMemory.enabled? && InMemory.cache_alive?(created_at)
    wrapper = efs_class.find_by(uid) if wrapper.nil? && Efs::Tweet.cache_alive?(created_at)
    wrapper = s3_class.find_by(uid) if wrapper.nil?

    time = "elapsed=#{sprintf("%.3f sec", Time.zone.now - created_at)} duration=#{sprintf("%.3f sec", Time.zone.now - start)}"
    if wrapper.nil?
      logger.info "#{__method__}: Failed twitter_user_id=#{id} uid=#{uid} #{time}"
      logger.info caller.join("\n")
      []
    else
      logger.info "#{__method__}: Found twitter_user_id=#{id} uid=#{uid} wrapper=#{wrapper.class} #{time}"
      wrapper.tweets || []
    end
  end
end
