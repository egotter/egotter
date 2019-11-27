require 'active_support/concern'

module Concerns::TwitterUser::Utils
  extend ActiveSupport::Concern

  class_methods do
    def latest_by(condition)
      order(created_at: :desc).find_by(condition)
    end
  end

  included do
    scope :creation_completed, -> do
      where.not('friends_size = 0 and followers_size = 0')
    end

    scope :has_user, -> do
      where('user_id != -1')
    end
  end

  # Reason1: too many friends
  # Reason2: near zero friends
  def no_need_to_import_friendships?
    friends_size == 0 && followers_size == 0
  end

  def consistent?(uids1, uids2)
    friends_size == uids1.size && followers_size == uids2.size
  end

  def import_batch_succeeded?
    (friends_size == 0 && friends_count == 0 && followers_size == 0 && followers_count == 0) ||
        ((friends_size - friends_count).abs <= 1 && (followers_size - followers_count).abs <= 1)
  end

  def import_batch_failed?
    !import_batch_succeeded?
  end

  # #diff calls this method in context of new record
  def friend_uids
    if new_record?
      @friend_uids
    else
      if instance_variable_defined?(:@persisted_friend_uids)
        @persisted_friend_uids
      else
        @persisted_friend_uids = Efs::TwitterUser.find_by(id)&.fetch(:friend_uids, nil)
        @persisted_friend_uids = S3::Friendship.find_by(twitter_user_id: id)&.fetch(:friend_uids, nil) if @persisted_friend_uids.nil?
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
        @persisted_follower_uids = Efs::TwitterUser.find_by(id)&.fetch(:follower_uids, nil)
        @persisted_follower_uids = S3::Followership.find_by(twitter_user_id: id)&.fetch(:follower_uids, nil) if @persisted_follower_uids.nil?
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

  def fresh?(attr = :updated_at, seconds: CREATE_RECORD_INTERVAL)
    logger.warn "Deprecated calling #fresh?"
    too_short_create_interval?
  end

  def too_short_create_interval?(interval = nil)
    interval = CREATE_RECORD_INTERVAL unless interval
    interval.seconds.ago < created_at
  end
end
