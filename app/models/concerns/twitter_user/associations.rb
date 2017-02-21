require 'active_support/concern'

module Concerns::TwitterUser::Associations
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    with_options foreign_key: :from_id, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :statuses
      obj.has_many :mentions
      obj.has_many :search_results
      obj.has_many :favorites
    end

    with_options primary_key: :id, foreign_key: :from_id, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friendships, -> { order(sequence: :asc) }
      obj.has_many :followerships, -> { order(sequence: :asc) }
    end

    with_options dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friends,   through: :friendships, class_name: 'TwitterDB::User'
      obj.has_many :followers, through: :followerships, class_name: 'TwitterDB::User'
    end

    with_options primary_key: :uid, foreign_key: :from_uid, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :unfriendships, -> { order(sequence: :asc) }
      obj.has_many :unfollowerships, -> { order(sequence: :asc) }
    end

    with_options dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :unfriends,   through: :unfriendships, class_name: 'TwitterDB::User'
      obj.has_many :unfollowers, through: :unfollowerships, class_name: 'TwitterDB::User'
    end

    with_options primary_key: :uid, foreign_key: :from_uid, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :one_sided_friendships,   -> { order(sequence: :asc) }
      obj.has_many :one_sided_followerships, -> { order(sequence: :asc) }
      obj.has_many :mutual_friendships,      -> { order(sequence: :asc) }
    end

    with_options dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :one_sided_friends,   through: :one_sided_friendships,   class_name: 'TwitterDB::User'
      obj.has_many :one_sided_followers, through: :one_sided_followerships, class_name: 'TwitterDB::User'
      obj.has_many :mutual_friends,      through: :mutual_friendships,      class_name: 'TwitterDB::User'
    end
  end
end
