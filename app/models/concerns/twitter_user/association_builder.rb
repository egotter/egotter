require 'active_support/concern'

module Concerns::TwitterUser::AssociationBuilder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::Validation

  class_methods do
  end

  included do
  end

  def build_friends_and_followers(friend_ids, follower_ids)
    self.friends_size = self.followers_size = 0

    if friend_ids&.any?
      self.friend_uids = friend_ids
      self.friends_size = friend_ids.size
    else
      self.friend_uids = []
      self.friends_size = 0
    end

    if follower_ids&.any?
      self.follower_uids = follower_ids
      self.followers_size = follower_ids.size
    else
      self.follower_uids = []
      self.followers_size = 0
    end
  end

  # Each process takes a few seconds if the relation has thousands of objects.
  def build_other_relations(relations)
    user_timeline, mentions_timeline, _favorites = %i(user_timeline mentions_timeline favorites).map { |key| relations[key] }

    if (mentions_timeline.nil? || mentions_timeline.empty?) && relations.has_key?(:search)
      mentions_timeline = relations[:search].reject { |status| uid == status[:user][:id] || status[:text].start_with?("RT @#{screen_name}") }
    end

    bm_build_relations("build user_timeline size=#{user_timeline&.size}") do
      # user_timeline.each { |status| statuses.build(TwitterDB::Status.attrs_by(twitter_user: self, status: status)) } if user_timeline&.any?
      @reserved_statuses = user_timeline.map { |status| TwitterDB::Status.new(TwitterDB::Status.attrs_by(twitter_user: self, status: status)) } if user_timeline&.any?
    end

    bm_build_relations("build mentions_timeline size=#{mentions_timeline&.size}") do
      # mentions_timeline.each { |status| mentions.build(TwitterDB::Mention.attrs_by(twitter_user: self, status: status)) } if mentions_timeline&.any?
      @reserved_mentions = mentions_timeline.map { |status| TwitterDB::Mention.new(TwitterDB::Mention.attrs_by(twitter_user: self, status: status)) } if mentions_timeline&.any?
    end

    bm_build_relations("build _favorites size=#{_favorites&.size}") do
      # _favorites.each { |status| favorites.build(TwitterDB::Favorite.attrs_by(twitter_user: self, status: status)) } if _favorites&.any?
      @reserved_favorites = _favorites.map { |status| TwitterDB::Favorite.new(TwitterDB::Favorite.attrs_by(twitter_user: self, status: status)) } if _favorites&.any?
    end
  end

  module Instrumentation
    def bm_build_relations(message, &block)
      start = Time.zone.now
      yield
      @bm_build_relations[message] = Time.zone.now - start
    end

    def build_other_relations(*args, &blk)
      @bm_build_relations = {}
      start = Time.zone.now

      super

      elapsed = Time.zone.now - start
      @bm_build_relations['sum'] = @bm_build_relations.values.sum
      @bm_build_relations['elapsed'] = elapsed

      logger.info "Benchmark CreateTwitterUserRequest AssociationBuilder id=#{id} user_id=#{user_id} uid=#{uid} #{sprintf("%.3f sec", elapsed)}"
      logger.info "Benchmark CreateTwitterUserRequest AssociationBuilder id=#{id} user_id=#{user_id} uid=#{uid} #{@bm_build_relations.inspect}"
    end
  end
  prepend Instrumentation
end
