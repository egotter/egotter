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
    end

    if follower_ids&.any?
      self.follower_uids = follower_ids
      self.followers_size = follower_ids.size
    end
  end

  # Each process takes a few seconds if the relation has thousands of objects.
  def build_other_relations(relations)
    user_timeline, mentions_timeline, _favorites = %i(user_timeline mentions_timeline favorites).map { |key| relations[key] }

    if (mentions_timeline.nil? || mentions_timeline.empty?) && relations.has_key?(:search)
      mentions_timeline = relations[:search].reject {|status| uid == status[:user][:id] || status[:text].start_with?("RT @#{screen_name}")}
    end

    user_timeline.each { |status| statuses.build(TwitterDB::Status.attrs_by(twitter_user: self, status: status)) } if user_timeline&.any?
    mentions_timeline.each { |status| mentions.build(TwitterDB::Mention.attrs_by(twitter_user: self, status: status)) } if mentions_timeline&.any?
    _favorites.each { |status| favorites.build(TwitterDB::Favorite.attrs_by(twitter_user: self, status: status)) } if _favorites&.any?
  end
end
