require 'active_support/concern'

module Concerns::TwitterDB::User::Associations
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    default_options = {dependent: :destroy, validate: false, autosave: false}
    order_by_sequence_asc = -> { order(sequence: :asc) }

    # with_options default_options.merge(primary_key: :uid, foreign_key: :user_uid) do |obj|
    #   obj.has_many :friendships,   order_by_sequence_asc, class_name: 'TwitterDB::Friendship'
    #   obj.has_many :followerships, order_by_sequence_asc, class_name: 'TwitterDB::Followership'
    # end

    with_options default_options.merge(primary_key: :uid, foreign_key: :uid) do |obj|
      obj.has_many :statuses,  order_by_sequence_asc, class_name: 'TwitterDB::Status'
      obj.has_many :favorites, order_by_sequence_asc, class_name: 'TwitterDB::Favorite'
      obj.has_many :mentions,  order_by_sequence_asc, class_name: 'TwitterDB::Mention'
    end

    with_options default_options.merge(primary_key: :uid, foreign_key: :uid) do |obj|
      obj.has_one :profile, class_name: 'TwitterDB::Profile'
    end

    with_options default_options.merge(primary_key: :uid, foreign_key: :from_uid) do |obj|
      obj.has_many :unfriendships,     order_by_sequence_asc
      obj.has_many :unfollowerships,   order_by_sequence_asc

      obj.has_many :block_friendships, order_by_sequence_asc
    end

    with_options default_options.merge(class_name: 'TwitterDB::User') do |obj|
      # obj.has_many :friends,       through: :friendships
      # obj.has_many :followers,     through: :followerships

      obj.has_many :unfriends,     through: :unfriendships
      obj.has_many :unfollowers,   through: :unfollowerships

      obj.has_many :block_friends, through: :block_friendships
    end
  end

  def blocking_or_blocked_uids
    # logger.warn "DEPRECATED WARNING: blocking_or_blocked_uids"
    # block_friendships.pluck(:friend_uid).uniq
    unfriendships.where(friend_uid: unfollowerships.pluck(:follower_uid)).pluck(:friend_uid).uniq
  end

  def blocking_or_blocked
    # logger.warn "DEPRECATED WARNING: blocking_or_blocked"
    # block_friends.distinct(:uid)
    # unfriends.where(uid: unfollowerships.pluck(:follower_uid)).uniq(&:uid)
    unfriends.where(uid: unfollowerships.pluck(:follower_uid))
  end
end
