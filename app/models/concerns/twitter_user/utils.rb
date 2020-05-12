require 'active_support/concern'

module Concerns::TwitterUser::Utils
  extend ActiveSupport::Concern

  # Reason1: too many friends
  # Reason2: near zero friends
  def no_need_to_import_friendships?
    friends_size == 0 && followers_size == 0
  end

  # #diff calls this method in context of new record
  def friend_uids
    if new_record?
      @reserved_friend_uids
    else
      if instance_variable_defined?(:@persisted_friend_uids)
        @persisted_friend_uids
      else
        uids = nil
        uids = InMemory::TwitterUser.find_by(id)&.friend_uids if InMemory.enabled? && InMemory.cache_alive?(created_at)
        uids = Efs::TwitterUser.find_by(id)&.friend_uids if uids.nil? && Efs.enabled?
        uids = S3::Friendship.find_by(twitter_user_id: id)&.friend_uids if uids.nil?
        uids = [] if uids.nil?
        @persisted_friend_uids = uids
      end
    end
  end

  # TODO Remove later
  def friend_uids=(uids)
    logger.warn '#friend_uids= is deprecated'
    @reserved_friend_uids = uids
  end

  # #diff calls this method in context of new record
  def follower_uids
    if new_record?
      @reserved_follower_uids
    else
      if instance_variable_defined?(:@persisted_follower_uids)
        @persisted_follower_uids
      else
        uids = nil
        uids = InMemory::TwitterUser.find_by(id)&.follower_uids if InMemory.enabled? && InMemory.cache_alive?(created_at)
        uids = Efs::TwitterUser.find_by(id)&.follower_uids if uids.nil? && Efs.enabled?
        uids = S3::Followership.find_by(twitter_user_id: id)&.follower_uids if uids.nil?
        uids = [] if uids.nil?
        @persisted_follower_uids = uids
      end
    end
  end

  # TODO Remove later
  def follower_uids=(uids)
    logger.warn '#follower_uids= is deprecated'
    @reserved_follower_uids = uids
  end

  # TODO Remove later
  def size
    logger.warn 'TwitterUser#size is deprecated'
    TwitterUser.where(uid: uid).size
  end

  CREATE_RECORD_INTERVAL = 30.minutes

  def too_short_create_interval?(interval = nil)
    interval = CREATE_RECORD_INTERVAL unless interval
    interval.seconds.ago < created_at
  end

  def next_creation_time(interval = nil)
    interval = CREATE_RECORD_INTERVAL unless interval
    created_at + interval.seconds
  end
end
