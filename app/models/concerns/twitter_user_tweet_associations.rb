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
    data = nil
    exceptions = []

    begin
      data = memory_class.find_by(uid) if InMemory.enabled? && InMemory.cache_alive?(created_at)
    rescue => e
      exceptions << e
    end

    begin
      data = efs_class.find_by(uid) if data.nil? && Efs::Tweet.cache_alive?(created_at)
    rescue => e
      exceptions << e
    end

    begin
      data = s3_class.find_by(uid) if data.nil?
    rescue => e
      exceptions << e
    end

    if data.nil?
      Rails.logger.warn "Fetching tweets is failed. uid=#{uid} exceptions=#{exceptions.inspect}"
      Rails.logger.info caller.join("\n")
      []
    else
      data.tweets || []
    end
  end
end
