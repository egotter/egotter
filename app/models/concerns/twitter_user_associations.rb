require 'active_support/concern'

module TwitterUserAssociations
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    with_options(optional: true) do |obj|
      obj.belongs_to :user
      obj.belongs_to :twitter_db_user, primary_key: :uid, foreign_key: :uid, class_name: 'TwitterDB::User'
    end

    with_options(primary_key: :uid, foreign_key: :uid, dependent: :destroy, validate: false, autosave: false) do |obj|
      obj.has_one :usage_stat
      # obj.has_one :audience_insight
      obj.has_one :close_friends_og_image
    end
  end

  def audience_insight
    logger.warn '#audience_insight is deprecated'
    nil
  end

  class RelationshipProxy
    def initialize(data)
      @data = data
      @limit = nil
    end

    def size
      @data.uids.size
    end

    def limit(count)
      @limit = count
      self
    end

    def pluck(*args)
      if @limit
        @data.uids.take(@limit)
      else
        @data.uids
      end
    end
  end

  def close_friendships
    if (from_s3 = S3::CloseFriendship.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      CloseFriendship.where(from_uid: uid).order(sequence: :asc)
    end
  end

  def favorite_friendships
    if (from_s3 = S3::FavoriteFriendship.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      FavoriteFriendship.where(from_uid: uid).order(sequence: :asc)
    end
  end

  def mutual_friendships
    if (from_s3 = S3::MutualFriendship.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      MutualFriendship.where(from_uid: uid).order(sequence: :asc)
    end
  end

  def one_sided_friendships
    if (from_s3 = S3::OneSidedFriendship.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      OneSidedFriendship.where(from_uid: uid).order(sequence: :asc)
    end
  end

  def one_sided_followerships
    if (from_s3 = S3::OneSidedFollowership.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      OneSidedFollowership.where(from_uid: uid).order(sequence: :asc)
    end
  end

  def inactive_friendships
    if (from_s3 = S3::InactiveFriendship.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      InactiveFriendship.where(from_uid: uid).order(sequence: :asc)
    end
  end

  def inactive_followerships
    if (from_s3 = S3::InactiveFollowership.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      InactiveFollowership.where(from_uid: uid).order(sequence: :asc)
    end
  end

  def inactive_mutual_friendships
    if (from_s3 = S3::InactiveMutualFriendship.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      InactiveMutualFriendship.where(from_uid: uid).order(sequence: :asc)
    end
  end

  def mutual_unfriendships
    if (from_s3 = S3::MutualUnfriendship.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      BlockFriendship.where(from_uid: uid).order(sequence: :asc)
    end
  end

  def unfriendships
    if (from_s3 = S3::Unfriendship.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      Unfriendship.where(from_uid: uid).order(sequence: :asc)
    end
  end

  def unfollowerships
    if (from_s3 = S3::Unfollowership.where(uid: uid))
      RelationshipProxy.new(from_s3)
    else
      logger.info "#{__method__}: Fetch records from outdated table uid=#{uid}"
      Unfollowership.where(from_uid: uid).order(sequence: :asc)
    end
  end

  FETCH_USERS_LIMIT = 10000

  def close_friends(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: close_friend_uids.take(limit))
  end

  def favorite_friends(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: favorite_friend_uids.take(limit))
  end

  def mutual_friends(limit: FETCH_USERS_LIMIT, inactive: nil)
    TwitterDB::User.where_and_order_by_field(uids: mutual_friend_uids.take(limit), inactive: inactive)
  end

  def one_sided_friends(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: one_sided_friend_uids.take(limit))
  end

  def one_sided_followers(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: one_sided_follower_uids.take(limit))
  end

  def inactive_friends(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: inactive_friend_uids.take(limit))
  end

  def inactive_followers(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: inactive_follower_uids.take(limit))
  end

  def inactive_mutual_friends(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: inactive_mutual_friend_uids.take(limit))
  end

  def friends(limit: FETCH_USERS_LIMIT, inactive: nil)
    TwitterDB::User.where_and_order_by_field(uids: friend_uids.take(limit), inactive: inactive)
  end

  def followers(limit: FETCH_USERS_LIMIT, inactive: nil)
    TwitterDB::User.where_and_order_by_field(uids: follower_uids.take(limit), inactive: inactive)
  end

  def mutual_unfriends(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: mutual_unfriend_uids.take(limit))
  end

  def unfriends(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: unfriend_uids.take(limit))
  end

  def unfollowers(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: unfollower_uids.take(limit))
  end

  def blockers(limit: FETCH_USERS_LIMIT)
    TwitterDB::User.where_and_order_by_field(uids: blocker_uids.take(limit))
  end

  def top_follower
    if instance_variable_defined?(:@top_follower)
      @top_follower
    else
      @top_follower = TwitterDB::User.find_by(uid: top_follower_uid)
    end
  end

  def close_friend_uids
    close_friendships.pluck(:friend_uid)
  end

  def favorite_friend_uids
    favorite_friendships.pluck(:friend_uid)
  end

  def mutual_friend_uids
    mutual_friendships.pluck(:friend_uid)
  end

  def one_sided_friend_uids
    one_sided_friendships.pluck(:friend_uid)
  end

  def one_sided_follower_uids
    one_sided_followerships.pluck(:follower_uid)
  end

  def inactive_mutual_friend_uids
    inactive_mutual_friendships.pluck(:friend_uid)
  end

  def inactive_friend_uids
    inactive_friendships.pluck(:friend_uid)
  end

  def inactive_follower_uids
    inactive_followerships.pluck(:follower_uid)
  end

  def mutual_unfriend_uids
    mutual_unfriendships.pluck(:friend_uid)
  end

  def unfriend_uids
    unfriendships.pluck(:friend_uid)
  end

  def unfollower_uids
    unfollowerships.pluck(:follower_uid)
  end

  # TODO Remove later
  def blocking_uids
    BlockingRelationship.where(from_uid: uid).limit(1000).pluck(:to_uid)
  end

  def blocker_uids
    BlockingRelationship.where(to_uid: uid).limit(FETCH_USERS_LIMIT).pluck(:from_uid)
  end

  def blockers_size
    BlockingRelationship.where(to_uid: uid).size
  end

  def muters_size
    MutingRelationship.where(to_uid: uid).size
  end
end
