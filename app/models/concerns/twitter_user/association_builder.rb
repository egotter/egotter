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
      friend_ids.each.with_index { |friend_id, i| friendships.build(friend_uid: friend_id, sequence: i) }
      self.friends_size = friend_ids.size
    end

    if follower_ids&.any?
      follower_ids.each.with_index { |follower_id, i| followerships.build(follower_uid: follower_id, sequence: i) }
      self.followers_size = follower_ids.size
    end
  end

  # Each process takes a few seconds if the relation has thousands of objects.
  def build_other_relations(relations)
    user_timeline, mentions_timeline, search, _favorites = %i(user_timeline mentions_timeline search favorites).map { |key| relations[key] }

    user_timeline.each { |status| statuses.build(_status_to_hash(status)) } if user_timeline&.any?
    mentions_timeline.each { |mention| mentions.build(_status_to_hash(mention)) } if mentions_timeline&.any?

    if search&.any?
      search.each { |status| search_results.build(_status_to_hash(status)) }
      search_results.each { |status| status.query = mention_name }
    end

    _favorites.each { |favorite| favorites.build(_status_to_hash(favorite)) } if _favorites&.any?
  end

  def _status_to_hash(status)
    {uid: status[:user][:id], screen_name: status[:user][:screen_name], status_info: status.slice(*::Status::STATUS_SAVE_KEYS).to_json}
  end
end
