require 'active_support/concern'

module Concerns::TwitterUser::Persistence
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    # This method is processed on `after_commit` to avoid long transaction.
    after_commit(on: :create) do

      perform_after_commit
      # Set friends_size and followers_size in AssociationBuilder#build_friends_and_followers

    rescue => e
      # ActiveRecord::RecordNotFound Couldn't find TwitterUser with 'id'=00000
      # ActiveRecord::StatementInvalid Mysql2::Error: Deadlock found when trying to get lock;
      logger.warn "#{__method__}: #{e.class} #{e.message.truncate(120)} #{self.inspect}"
      logger.info e.backtrace.join("\n")
      destroy
    end
  end

  # Don't create threads in this method!
  def perform_after_commit
    bm_after_commit('Efs::TwitterUser.import_from!') do
      Efs::TwitterUser.import_from!(id, uid, screen_name, profile_text, @reserved_friend_uids, @reserved_follower_uids)
    end

    bm_after_commit('S3::Friendship.import_from!') do
      S3::Friendship.import_from!(id, uid, screen_name, @reserved_friend_uids, async: true)
    end

    bm_after_commit('S3::Followership.import_from!') do
      S3::Followership.import_from!(id, uid, screen_name, @reserved_follower_uids, async: true)
    end

    bm_after_commit('S3::Profile.import_from!') do
      S3::Profile.import_from!(id, uid, screen_name, profile_text, async: true)
    end

    status_tweets = @reserved_statuses.map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) }
    favorite_tweets = @reserved_favorites.map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) }
    mention_tweets = @reserved_mentions.map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) }

    # S3

    bm_after_commit('S3::StatusTweet.import_from!') do
      S3::StatusTweet.import_from!(uid, screen_name, status_tweets)
    end

    bm_after_commit('S3::FavoriteTweet.import_from!') do
      S3::FavoriteTweet.import_from!(uid, screen_name, favorite_tweets)
    end

    bm_after_commit('S3::MentionTweet.import_from!') do
      S3::MentionTweet.import_from!(uid, screen_name, mention_tweets)
    end

    # EFS (Automatically deleted)

    bm_after_commit('Efs::StatusTweet.import_from!') do
      Efs::StatusTweet.import_from!(uid, screen_name, status_tweets)
    end

    bm_after_commit('Efs::FavoriteTweet.import_from!') do
      Efs::FavoriteTweet.import_from!(uid, screen_name, favorite_tweets)
    end

    bm_after_commit('Efs::MentionTweet.import_from!') do
      Efs::MentionTweet.import_from!(uid, screen_name, mention_tweets)
    end
  end

  module Instrumentation
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

      logger.info "Benchmark CreateTwitterUserRequest persistence id=#{id} user_id=#{user_id} uid=#{uid} #{sprintf("%.3f sec", elapsed)}"
      logger.info "Benchmark CreateTwitterUserRequest persistence id=#{id} user_id=#{user_id} uid=#{uid} #{@bm_after_commit.inspect}"
    end
  end
  prepend Instrumentation
end
