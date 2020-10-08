require 'active_support/concern'

module TwitterUserPersistence
  extend ActiveSupport::Concern

  included do
    attr_accessor :copied_friend_uids, :copied_follower_uids, :copied_user_timeline, :copied_mention_tweets, :copied_favorite_tweets

    after_create :perform_before_commit
    after_create_commit :perform_after_commit
  end

  # WARNING: Don't create threads in this method!
  def perform_before_commit
    # The InMemory resources are automatically deleted in 10 minutes.

    bm_before_commit('InMemory::TwitterUser.import_from') do
      InMemory::TwitterUser.import_from(id, uid, screen_name, profile_text, copied_friend_uids, copied_follower_uids)
    end

    if copied_user_timeline.present?
      bm_before_commit('InMemory::StatusTweet.import_from') do
        InMemory::StatusTweet.import_from(uid, copied_user_timeline)
      end
    end

    if copied_favorite_tweets.present?
      bm_before_commit('InMemory::FavoriteTweet.import_from') do
        InMemory::FavoriteTweet.import_from(uid, copied_favorite_tweets)
      end
    end

    if copied_mention_tweets.present?
      bm_before_commit('InMemory::MentionTweet.import_from') do
        InMemory::MentionTweet.import_from(uid, copied_mention_tweets)
      end
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(120)} twitter_user=#{self.inspect}"
    logger.info e.backtrace.join("\n")
    raise ActiveRecord::Rollback
  end

  # This method is processed on `after_commit` to avoid long transaction.
  # WARNING: Don't create threads in this method!
  def perform_after_commit
    bm_after_commit('Efs::TwitterUser.import_from!') do
      Efs::TwitterUser.import_from!(id, uid, screen_name, profile_text, copied_friend_uids, copied_follower_uids)
    end

    # Efs::StatusTweet, Efs::FavoriteTweet and Efs::MentionTweet are not imported for performance reasons

    bm_after_commit('S3::Friendship.import_from!') do
      S3::Friendship.import_from!(id, uid, screen_name, copied_friend_uids, async: true)
    end

    bm_after_commit('S3::Followership.import_from!') do
      S3::Followership.import_from!(id, uid, screen_name, copied_follower_uids, async: true)
    end

    bm_after_commit('S3::Profile.import_from!') do
      S3::Profile.import_from!(id, uid, screen_name, profile_text, async: true)
    end

    if copied_user_timeline.present?
      bm_after_commit('S3::StatusTweet.import_from!') do
        S3::StatusTweet.import_from!(uid, screen_name, copied_user_timeline)
      end
    end

    if copied_favorite_tweets.present?
      bm_after_commit('S3::FavoriteTweet.import_from!') do
        S3::FavoriteTweet.import_from!(uid, screen_name, copied_favorite_tweets)
      end
    end

    if copied_mention_tweets.present?
      bm_after_commit('S3::MentionTweet.import_from!') do
        S3::MentionTweet.import_from!(uid, screen_name, copied_mention_tweets)
      end
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(120)} twitter_user=#{self.inspect}"
    logger.info e.backtrace.join("\n")
    destroy
  end

  module Instrumentation
    def bm_before_commit(message, &block)
      start = Time.zone.now
      yield
      @bm_before_commit[message] = Time.zone.now - start
    end

    def perform_before_commit(*args, &blk)
      @bm_before_commit = {}
      start = Time.zone.now

      super

      elapsed = Time.zone.now - start
      @bm_before_commit['sum'] = @bm_before_commit.values.sum
      @bm_before_commit['elapsed'] = elapsed

      logger.info "Benchmark CreateTwitterUserRequest #{__method__} id=#{id} user_id=#{user_id} uid=#{uid} #{sprintf("%.3f sec", elapsed)} #{@bm_before_commit.inspect}"
    end

    def bm_after_commit(message, &block)
      start = Time.zone.now
      yield
      @bm_after_commit[message] = Time.zone.now - start
    end

    def perform_after_commit(*args, &blk)
      @bm_after_commit = {}
      start = Time.zone.now

      super

      elapsed = Time.zone.now - start
      @bm_after_commit['sum'] = @bm_after_commit.values.sum
      @bm_after_commit['elapsed'] = elapsed

      logger.info "Benchmark CreateTwitterUserRequest #{__method__} id=#{id} user_id=#{user_id} uid=#{uid} #{sprintf("%.3f sec", elapsed)} #{@bm_after_commit.inspect}"
    end
  end
  prepend Instrumentation
end
