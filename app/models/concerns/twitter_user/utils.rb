require 'active_support/concern'

module Concerns::TwitterUser::Utils
  extend ActiveSupport::Concern

  # Reason1: too many friends
  # Reason2: near zero friends
  def no_need_to_import_friendships?
    friends_size == 0 && followers_size == 0
  end

  def too_little_friends?
    friends_count == 0 && followers_count == 0 && friends_size == 0 && followers_size == 0
  end

  # #diff calls this method in context of new record
  def friend_uids
    if new_record?
      @reserved_friend_uids
    else
      if instance_variable_defined?(:@persisted_friend_uids)
        @persisted_friend_uids
      else
        @persisted_friend_uids = fetch_friend_uids
      end
    end
  end

  # #diff calls this method in context of new record
  def follower_uids
    if new_record?
      @reserved_follower_uids
    else
      if instance_variable_defined?(:@persisted_follower_uids)
        @persisted_follower_uids
      else
        @persisted_follower_uids = fetch_follower_uids
      end
    end
  end

  CREATE_RECORD_INTERVAL = 30.minutes

  def too_short_create_interval?(interval = nil)
    interval = CREATE_RECORD_INTERVAL unless interval
    interval.seconds.ago < created_at
  end

  private

  def fetch_friend_uids
    uids = nil
    uids = InMemory::TwitterUser.find_by(id)&.friend_uids if InMemory.enabled? && InMemory.cache_alive?(created_at)
    uids = Efs::TwitterUser.find_by(id)&.friend_uids if uids.nil? && Efs.enabled?
    uids = S3::Friendship.find_by(twitter_user_id: id)&.friend_uids if uids.nil?
    if uids.nil?
      logger.warn "#{__method__}: failed twitter_user_id=#{id} uid=#{uid} elapsed=#{sprintf("%.3f sec", Time.zone.now - created_at)}"
      logger.info caller.join("\n")
      []
    else
      uids
    end
  end

  def fetch_follower_uids
    uids = nil
    uids = InMemory::TwitterUser.find_by(id)&.follower_uids if InMemory.enabled? && InMemory.cache_alive?(created_at)
    uids = Efs::TwitterUser.find_by(id)&.follower_uids if uids.nil? && Efs.enabled?
    uids = S3::Followership.find_by(twitter_user_id: id)&.follower_uids if uids.nil?
    if uids.nil?
      logger.warn "#{__method__}: failed twitter_user_id=#{id} uid=#{uid} elapsed=#{sprintf("%.3f sec", Time.zone.now - created_at)}"
      logger.info caller.join("\n")
      []
    else
      uids
    end
  end
end
