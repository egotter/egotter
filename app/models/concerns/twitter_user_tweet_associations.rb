require 'active_support/concern'

module TwitterUserTweetAssociations
  extend ActiveSupport::Concern

  def status_tweets
    fetch_tweets(__method__, InMemory::StatusTweet, S3::StatusTweet)
  end

  def favorite_tweets
    fetch_tweets(__method__, InMemory::FavoriteTweet, S3::FavoriteTweet)
  end

  def mention_tweets
    fetch_tweets(__method__, InMemory::MentionTweet, S3::MentionTweet)
  end

  private

  def fetch_tweets(method_name, memory_class, s3_class)
    data = nil
    exceptions = []
    source = nil
    start = Time.zone.now

    begin
      if InMemory.enabled? && InMemory.cache_alive?(created_at)
        data = memory_class.find_by(uid)
        source = 'memory'
      end
    rescue => e
      exceptions << e
    end

    begin
      if data.nil?
        data = s3_class.find_by(uid)
        source = 's3'
      end
    rescue => e
      exceptions << e
    end

    if data.nil?
      Airbag.info "Fetching #{method_name} failed", twitter_user_id: id, uid: uid, created_at: created_at.to_s(:db), exceptions: exceptions.inspect, caller: caller
      if exceptions.empty?
        ImportEmptyTweetsWorker.perform_async(s3_class, uid, screen_name)
      end
      []
    else
      Airbag.info "Fetching #{method_name} succeeded", twitter_user_id: id, uid: uid, source: source, elapsed: (Time.zone.now - start) if Rails.env.development?
      data.tweets || []
    end
  end
end
