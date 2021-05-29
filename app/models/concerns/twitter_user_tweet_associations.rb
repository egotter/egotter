require 'active_support/concern'

module TwitterUserTweetAssociations
  extend ActiveSupport::Concern

  def status_tweets
    fetch_tweets(__method__, InMemory::StatusTweet, Efs::StatusTweet, S3::StatusTweet)
  end

  def favorite_tweets
    fetch_tweets(__method__, InMemory::FavoriteTweet, Efs::FavoriteTweet, S3::FavoriteTweet)
  end

  def mention_tweets
    fetch_tweets(__method__, InMemory::MentionTweet, Efs::MentionTweet, S3::MentionTweet)
  end

  private

  def fetch_tweets(method_name, memory_class, efs_class, s3_class)
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
      Rails.logger.info "Fetching tweets is failed. method=#{method_name} id=#{id} screen_name=#{screen_name} created_at=#{created_at.to_s(:db)} exceptions=#{exceptions.inspect}"
      Rails.logger.info caller.join("\n")
      if exceptions.empty?
        ImportEmptyTweetsWorker.perform_async(s3_class, uid, screen_name)
      end
      []
    else
      data.tweets || []
    end
  end
end
