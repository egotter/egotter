require 'active_support/concern'

module Concerns::TwitterUser::Utils
  extend ActiveSupport::Concern

  class_methods do
    def latest_by(condition)
      order(created_at: :desc).find_by(condition)
    end

    def till(time)
      where('created_at < ?', time)
    end

    def cache_ready_interval
      1.seconds
    end
  end

  included do
    scope :creation_completed, -> do
      # friends_size != 0 AND followers_size != 0
      where.not(friends_size: 0, followers_size: 0)
    end

    scope :cache_ready, -> do
      where('created_at < ?', TwitterUser.cache_ready_interval.ago)
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
      @persisted_friend_uids ||= (S3::Friendship.find_by(twitter_user_id: id)[:friend_uids] || [])
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
      @persisted_follower_uids ||= (S3::Followership.find_by(twitter_user_id: id)[:follower_uids] || [])
    end
  end

  def follower_uids=(uids)
    @follower_uids = uids
  end

  def latest?
    id == TwitterUser.select(:id).latest_by(uid: uid).id
  end

  def one?
    TwitterUser.where(uid: uid).one?
  end

  def size
    TwitterUser.where(uid: uid).size
  end

  DEFAULT_SECONDS = Rails.configuration.x.constants['twitter_user_recently_created']

  def fresh?(attr = :updated_at, seconds: DEFAULT_SECONDS)
    Time.zone.now - send(attr) < seconds
  end
end
