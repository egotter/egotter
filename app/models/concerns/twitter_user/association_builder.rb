require 'active_support/concern'

module Concerns::TwitterUser::AssociationBuilder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::Validation

  class_methods do
  end

  included do
  end

  def build_friends_and_followers(friend_ids, follower_ids)
    prefix = 'AssociationBuilder#build'
    self.friends_size = self.followers_size = 0

    _benchmark("#{prefix} friend_ids") do
      friend_ids.each.with_index { |friend_id, i| friendships.build(friend_uid: friend_id, sequence: i) }
      self.friends_size = friend_ids.size
    end if friend_ids&.any?

    _benchmark("#{prefix} follower_ids") do
      follower_ids.each.with_index { |follower_id, i| followerships.build(follower_uid: follower_id, sequence: i) }
      self.followers_size = follower_ids.size
    end if follower_ids&.any?
  end

  # Each process takes a few seconds if the relation has thousands of objects.
  def build_other_relations(relations)
    prefix = 'AssociationBuilder#build'
    user_timeline, mentions_timeline, search, _favorites = %i(user_timeline mentions_timeline search favorites).map { |key| relations[key] }

    _benchmark("#{prefix} statuses") { user_timeline.each { |status| statuses.build(_status_to_hash(status)) } } if user_timeline&.any?
    _benchmark("#{prefix} mentions_timeline") { mentions_timeline.each { |mention| mentions.build(_status_to_hash(mention)) } } if mentions_timeline&.any?

    _benchmark("#{prefix} search_results") do
      search.each { |status| search_results.build(_status_to_hash(status)) }
      search_results.each { |status| status.query = mention_name }
    end if search&.any?

    _benchmark("#{prefix} favorites") { _favorites.each { |favorite| favorites.build(_status_to_hash(favorite)) } } if _favorites&.any?
  end

  def _status_to_hash(status)
    {uid: status.user.id, screen_name: status.user.screen_name, status_info: status.slice(*Status::STATUS_SAVE_KEYS).to_json}
  end
end
