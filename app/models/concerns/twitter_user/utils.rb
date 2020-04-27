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
      @friend_uids
    else
      if instance_variable_defined?(:@persisted_friend_uids)
        @persisted_friend_uids
      else
        @persisted_friend_uids = Efs::TwitterUser.find_by(id)&.friend_uids unless ENV['DISABLE_EFS_TWITTER_USER'] == '1'
        @persisted_friend_uids = S3::Friendship.find_by(twitter_user_id: id)&.friend_uids if @persisted_friend_uids.nil?
        @persisted_friend_uids = [] if @persisted_friend_uids.nil?
        @persisted_friend_uids
      end
    end
  end

  def friend_uids=(uids)
    @friend_uids = uids
  end

  # #diff calls this method in context of new record
  def follower_uids
    if new_record?
      @follower_uids
    else
      if instance_variable_defined?(:@persisted_follower_uids)
        @persisted_follower_uids
      else
        @persisted_follower_uids = Efs::TwitterUser.find_by(id)&.follower_uids unless ENV['DISABLE_EFS_TWITTER_USER'] == '1'
        @persisted_follower_uids = S3::Followership.find_by(twitter_user_id: id)&.follower_uids if @persisted_follower_uids.nil?
        @persisted_follower_uids = [] if @persisted_follower_uids.nil?
        @persisted_follower_uids
      end
    end
  end

  def follower_uids=(uids)
    @follower_uids = uids
  end

  def size
    TwitterUser.where(uid: uid).size
  end

  CREATE_RECORD_INTERVAL = Rails.configuration.x.constants['twitter_users']['create_record_interval']

  def too_short_create_interval?(interval = nil)
    interval = CREATE_RECORD_INTERVAL unless interval
    interval.seconds.ago < created_at
  end

  def next_creation_time(interval = nil)
    interval = CREATE_RECORD_INTERVAL unless interval
    created_at + interval.seconds
  end
end
