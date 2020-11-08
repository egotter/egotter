require 'active_support/concern'

module TwitterUserTweetAssociations
  extend ActiveSupport::Concern

  # TODO Return an instance of Efs::StatusTweet or S3::StatusTweet
  def status_tweets
    tweets = []
    start = Time.zone.now

    tweets = InMemory::StatusTweet.find_by(uid) if InMemory.enabled? && InMemory.cache_alive?(created_at)
    tweets = Efs::StatusTweet.where(uid: uid) if tweets.blank? && Efs::Tweet.cache_alive?(created_at)
    tweets = S3::StatusTweet.where(uid: uid) if tweets.blank?

    time = "elapsed=#{sprintf("%.3f sec", Time.zone.now - created_at)} duration=#{sprintf("%.3f sec", Time.zone.now - start)}"
    if tweets.blank?
      logger.warn "#{__method__}: Failed twitter_user_id=#{id} uid=#{uid} #{time}"
      logger.info caller.join("\n")
      []
    else
      logger.info "#{__method__}: Found twitter_user_id=#{id} uid=#{uid} wrapper=#{tweets.first.class} #{time}"
      tweets.map { |tweet| TwitterDB::Status.new(uid: uid, screen_name: screen_name, raw_attrs_text: tweet.raw_attrs_text) }
    end
  end

  # TODO Return an instance of Efs::FavoriteTweet or S3::FavoriteTweet
  def favorite_tweets
    tweets = []
    start = Time.zone.now

    tweets = InMemory::FavoriteTweet.find_by(uid) if InMemory.enabled? && InMemory.cache_alive?(created_at)
    tweets = Efs::FavoriteTweet.where(uid: uid) if tweets.blank? && Efs::Tweet.cache_alive?(created_at)
    tweets = S3::FavoriteTweet.where(uid: uid) if tweets.blank?

    time = "elapsed=#{sprintf("%.3f sec", Time.zone.now - created_at)} duration=#{sprintf("%.3f sec", Time.zone.now - start)}"
    if tweets.blank?
      logger.warn "#{__method__}: Failed twitter_user_id=#{id} uid=#{uid} #{time}"
      logger.info caller.join("\n")
      []
    else
      logger.info "#{__method__}: Found twitter_user_id=#{id} uid=#{uid} wrapper=#{tweets.first.class} #{time}"
      tweets.map { |tweet| TwitterDB::Status.new(uid: uid, screen_name: screen_name, raw_attrs_text: tweet.raw_attrs_text) }
    end
  end

  # TODO Return an instance of Efs::MentionTweet or S3::MentionTweet
  def mention_tweets
    tweets = []
    start = Time.zone.now

    tweets = InMemory::MentionTweet.find_by(uid) if InMemory.enabled? && InMemory.cache_alive?(created_at)
    tweets = Efs::MentionTweet.where(uid: uid) if tweets.blank? && Efs::Tweet.cache_alive?(created_at)
    tweets = S3::MentionTweet.where(uid: uid) if tweets.blank?

    time = "elapsed=#{sprintf("%.3f sec", Time.zone.now - created_at)} duration=#{sprintf("%.3f sec", Time.zone.now - start)}"
    if tweets.blank?
      logger.warn "#{__method__}: Failed twitter_user_id=#{id} uid=#{uid} #{time}"
      logger.info caller.join("\n")
      []
    else
      logger.info "#{__method__}: Found twitter_user_id=#{id} uid=#{uid} wrapper=#{tweets.first.class} #{time}"
      tweets.map { |tweet| TwitterDB::Status.new(uid: uid, screen_name: screen_name, raw_attrs_text: tweet.raw_attrs_text) }
    end
  end
end
