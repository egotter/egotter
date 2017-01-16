require 'active_support/concern'

module Concerns::TwitterUser::Associations
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    with_options foreign_key: :from_id, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friends
      obj.has_many :followers
      obj.has_many :statuses
      obj.has_many :mentions
      obj.has_many :search_results
      obj.has_many :favorites
    end

    with_options primary_key: :uid, foreign_key: :from_uid, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :unfriendships, -> { order(sequence: :asc) }
      obj.has_many :unfollowerships, -> { order(sequence: :asc) }
    end

    with_options dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :unfriends,   through: :unfriendships
      obj.has_many :unfollowers, through: :unfollowerships
    end

    with_options primary_key: :id, foreign_key: :from_id, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friendships, -> { order(sequence: :asc) }
      obj.has_many :followerships, -> { order(sequence: :asc) }
    end

    def tmp_friends
      uids = friendships.pluck(:friend_uid)
      users = TwitterDB::User.where(uid: uids).index_by(&:uid)
      uids.map { |_uid| users[_uid] }
    end

    def tmp_followers
      uids = followerships.pluck(:follower_uid)
      users = TwitterDB::User.where(uid: uids).index_by(&:uid)
      uids.map { |_uid| users[_uid] }
    end
  end
end
