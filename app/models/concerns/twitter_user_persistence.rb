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

  def perform_after_commit
    data = {
        id: id,
        uid: uid,
        screen_name: screen_name,
        profile: profile_text,
        friend_uids: copied_friend_uids,
        follower_uids: copied_follower_uids,
        status_tweets: copied_user_timeline,
        favorite_tweets: copied_favorite_tweets,
        mention_tweets: copied_mention_tweets,
    }
    data = Base64.encode64(Zlib::Deflate.deflate(data.to_json))
    PerformAfterCommitWorker.perform_async(id, data)
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
      @bm_before_commit.transform_values! { |v| sprintf("%.3f", v) }

      logger.info "Benchmark CreateTwitterUserRequest before_commit twitter_user=#{id} user_id=#{user_id} uid=#{uid} #{@bm_before_commit.inspect}"
    end
  end
  prepend Instrumentation
end
