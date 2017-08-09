require 'active_support/concern'

module Concerns::TwitterUser::Associations
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    belongs_to :user

    default_options = {dependent: :destroy, validate: false, autosave: false}
    order_by_sequence_asc = -> { order(sequence: :asc) }

    with_options({primary_key: :id, foreign_key: :from_id}.update(default_options)) do |obj|
      obj.has_many :statuses
      obj.has_many :mentions
      obj.has_many :search_results
      obj.has_many :favorites

      obj.has_many :friendships, order_by_sequence_asc
      obj.has_many :followerships, order_by_sequence_asc
    end

    with_options({primary_key: :uid, foreign_key: :from_uid}.update(default_options)) do |obj|
      obj.has_many :unfriendships,   order_by_sequence_asc
      obj.has_many :unfollowerships, order_by_sequence_asc

      obj.has_many :one_sided_friendships,   order_by_sequence_asc
      obj.has_many :one_sided_followerships, order_by_sequence_asc
      obj.has_many :mutual_friendships,      order_by_sequence_asc

      obj.has_many :inactive_friendships,        order_by_sequence_asc
      obj.has_many :inactive_followerships,      order_by_sequence_asc
      obj.has_many :inactive_mutual_friendships, order_by_sequence_asc

      obj.has_many :favorite_friendships, order_by_sequence_asc
      obj.has_many :close_friendships,    order_by_sequence_asc
    end

    with_options({class_name: 'TwitterDB::User'}.update(default_options)) do |obj|
      obj.has_many :friends,   through: :friendships
      obj.has_many :followers, through: :followerships

      obj.has_many :unfriends,   through: :unfriendships
      obj.has_many :unfollowers, through: :unfollowerships

      obj.has_many :one_sided_friends,   through: :one_sided_friendships
      obj.has_many :one_sided_followers, through: :one_sided_followerships
      obj.has_many :mutual_friends,      through: :mutual_friendships

      obj.has_many :inactive_friends,        through: :inactive_friendships
      obj.has_many :inactive_followers,      through: :inactive_followerships
      obj.has_many :inactive_mutual_friends, through: :inactive_mutual_friendships

      obj.has_many :favorite_friends, through: :favorite_friendships
      obj.has_many :close_friends,    through: :close_friendships
    end
  end
end
