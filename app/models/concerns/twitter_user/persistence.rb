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

  def perform_after_commit
    benchmark('Efs::TwitterUser.import_from!') do
      Efs::TwitterUser.import_from!(id, uid, screen_name, profile_text, @friend_uids, @follower_uids)
    end

    benchmark('S3::Friendship.import_from!') do
      S3::Friendship.import_from!(id, uid, screen_name, @friend_uids, async: true)
    end

    benchmark('S3::Followership.import_from!') do
      S3::Followership.import_from!(id, uid, screen_name, @follower_uids, async: true)
    end

    benchmark('S3::Profile.import_from!') do
      S3::Profile.import_from!(id, uid, screen_name, profile_text, async: true)
    end

    # S3

    tweets = []
    benchmark('S3::StatusTweet.import_from! collect') do
      tweets = statuses.select(&:new_record?).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) }
    end
    benchmark('S3::StatusTweet.import_from! import') do
      S3::StatusTweet.import_from!(uid, screen_name, tweets)
    end

    tweets = []
    benchmark('S3::FavoriteTweet.import_from! collect') do
      tweets = favorites.select(&:new_record?).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) }
    end
    benchmark('S3::FavoriteTweet.import_from! import') do
      S3::FavoriteTweet.import_from!(uid, screen_name, tweets)
    end

    tweets = []
    benchmark('S3::MentionTweet.import_from! collect') do
      tweets = mentions.select(&:new_record?).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) }
    end
    benchmark('S3::MentionTweet.import_from! import') do
      S3::MentionTweet.import_from!(uid, screen_name, tweets)
    end

    # EFS

    tweets = []
    benchmark('Efs::StatusTweet.import_from! collect') do
      tweets = statuses.select(&:new_record?).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) }
    end
    benchmark('Efs::StatusTweet.import_from! import') do
      Efs::StatusTweet.import_from!(uid, screen_name, tweets)
    end

    tweets = []
    benchmark('Efs::FavoriteTweet.import_from! collect') do
      tweets = favorites.select(&:new_record?).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) }
    end
    benchmark('Efs::FavoriteTweet.import_from! import') do
      Efs::FavoriteTweet.import_from!(uid, screen_name, tweets)
    end

    tweets = []
    benchmark('Efs::MentionTweet.import_from! collect') do
      tweets = mentions.select(&:new_record?).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) }
    end
    benchmark('Efs::MentionTweet.import_from! import') do
      Efs::MentionTweet.import_from!(uid, screen_name, tweets)
    end
  end

  module Instrumentation
    def benchmark(message, &block)
      start = Time.zone.now
      yield
      @benchmark[message] = Time.zone.now - start
    end

    def perform_after_commit(*args, &blk)
      @benchmark = {}
      start = Time.zone.now

      super

      elapsed = Time.zone.now - start
      @benchmark['elapsed'] = elapsed
      @benchmark['sum'] = @benchmark.values.sum

      logger.info "Benchmark CreateTwitterUserRequest persistence id=#{id} user_id=#{user_id} uid=#{uid} #{sprintf("%.3f sec", elapsed)}"
      logger.info "Benchmark CreateTwitterUserRequest persistence id=#{id} user_id=#{user_id} uid=#{uid} #{@benchmark.inspect}"
    end
  end
  prepend Instrumentation
end
