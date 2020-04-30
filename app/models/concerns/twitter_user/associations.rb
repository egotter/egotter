require 'active_support/concern'

module Concerns::TwitterUser::Associations
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    with_options(optional: true) do |obj|
      obj.belongs_to :user
      obj.belongs_to :twitter_db_user, primary_key: :uid, foreign_key: :uid, class_name: 'TwitterDB::User'
    end

    default_options = {dependent: :destroy, validate: false, autosave: false}
    order_by_sequence_asc = -> { order(sequence: :asc) }

    with_options({primary_key: :uid, foreign_key: :uid}.update(default_options)) do |obj|
      obj.has_one :usage_stat
      obj.has_one :score
    end

    with_options({primary_key: :uid, foreign_key: :from_uid}.update(default_options)) do |obj|
      obj.has_many :one_sided_friendships,       order_by_sequence_asc
      obj.has_many :one_sided_followerships,     order_by_sequence_asc
      obj.has_many :mutual_friendships,          order_by_sequence_asc

      obj.has_many :inactive_friendships,        order_by_sequence_asc
      obj.has_many :inactive_followerships,      order_by_sequence_asc
      obj.has_many :inactive_mutual_friendships, order_by_sequence_asc

      obj.has_many :favorite_friendships,        order_by_sequence_asc
      obj.has_many :close_friendships,           order_by_sequence_asc
    end

    with_options({class_name: 'TwitterDB::User'}.update(default_options)) do |obj|
      obj.has_many :one_sided_friends,       through: :one_sided_friendships
      obj.has_many :one_sided_followers,     through: :one_sided_followerships
      obj.has_many :mutual_friends,          through: :mutual_friendships

      obj.has_many :inactive_friends,        through: :inactive_friendships
      obj.has_many :inactive_followers,      through: :inactive_followerships
      obj.has_many :inactive_mutual_friends, through: :inactive_mutual_friendships

      obj.has_many :favorite_friends,        through: :favorite_friendships
      obj.has_many :close_friends,           through: :close_friendships
    end

    # Aliases of twitter_db_user.*
    # IMPORTANT: The primary key of these associations is uid. If you update unfriendships,
    # all other records of twitter_users return same unfriendships.
    with_options default_options.merge(primary_key: :uid, foreign_key: :from_uid) do |obj|
      obj.has_many :unfriendships,     order_by_sequence_asc
      obj.has_many :unfollowerships,   order_by_sequence_asc
      obj.has_many :block_friendships, order_by_sequence_asc
    end

    with_options default_options.merge(class_name: 'TwitterDB::User') do |obj|
      obj.has_many :unfriends,     through: :unfriendships
      obj.has_many :unfollowers,   through: :unfollowerships
      obj.has_many :block_friends, through: :block_friendships
    end
  end

  def friends(limit: 100_000)
    TwitterDB::User.where_and_order_by_field(uids: friend_uids.take(limit))
  end

  def followers(limit: 100_000)
    TwitterDB::User.where_and_order_by_field(uids: follower_uids.take(limit))
  end

  def unfollower_uids
    unfollowerships.pluck(:follower_uid)
  end

  # TODO Return an instance of Efs::StatusTweet or S3::StatusTweet
  def status_tweets
    tweets = []
    tweets = ::Efs::StatusTweet.where(uid: uid) if created_at > ::Efs::StatusTweet.client.ttl.ago
    tweets = ::S3::StatusTweet.where(uid: uid) if tweets.blank?
    tweets.map { |tweet| ::TwitterDB::Status.new(uid: uid, screen_name: screen_name, raw_attrs_text: tweet.raw_attrs_text) }
  end

  # TODO Return an instance of Efs::FavoriteTweet or S3::FavoriteTweet
  def favorite_tweets
    tweets = []
    tweets = ::Efs::FavoriteTweet.where(uid: uid) if created_at > ::Efs::FavoriteTweet.client.ttl.ago
    tweets = ::S3::FavoriteTweet.where(uid: uid) if tweets.blank?
    tweets.map { |tweet| ::TwitterDB::Favorite.new(uid: uid, screen_name: screen_name, raw_attrs_text: tweet.raw_attrs_text) }
  end

  # TODO Return an instance of Efs::MentionTweet or S3::MentionTweet
  def mention_tweets
    tweets = []
    tweets = ::Efs::MentionTweet.where(uid: uid) if created_at > ::Efs::MentionTweet.client.ttl.ago
    tweets = ::S3::MentionTweet.where(uid: uid) if tweets.blank?
    tweets.map { |tweet| ::TwitterDB::Mention.new(uid: uid, screen_name: screen_name, raw_attrs_text: tweet.raw_attrs_text) }
  end

  def users_by(controller_name:, limit: 300)
    users =
        if controller_name == 'blocking_or_blocked'
          send(:block_friends)
        else
          send(controller_name)
        end
    users.is_a?(Array) ? users.take(limit) : users.limit(limit)
  end

  def common_users_by(controller_name:, friend:, limit: 300)
    send(controller_name, friend).take(limit)
  end
end
