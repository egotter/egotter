require 'active_support/concern'

module Concerns::TwitterUser::Utils
  extend ActiveSupport::Concern

  class_methods do
    def latest(uid)
      logger.warn "DEPRECATE WARNING: calling latest(uid)"
      latest_by(uid: uid)
    end

    def latest_by(uid:)
      order(created_at: :desc).find_by(uid: uid)
    end

    def till(time)
      where('created_at < ?', time)
    end

    def with_friends
      # friends_size != 0 AND followers_size != 0
      where.not(friends_size: 0, followers_size: 0)
    end
  end

  included do
  end

  # Reason1: too many friends
  # Reason2: near zero friends
  def friendless?
    friends_size == 0 && followers_size == 0
  end

  def consistent?(uids1, uids2)
    friends_size == uids1.size && followers_size == uids2.size
  end

  def inconsistent_because_import_didnt_run?
    (friends_size >= 0 && friends_size != friendships.size) ||
        (followers_size >= 0 && followers_size != followerships.size)
  end

  def inconsistent_because_import_failed?
    friends_size == -1 && followers_size == -1
  end

  def friend_uids
    new_record? ? friendships.map(&:friend_uid) : friendships.pluck(:friend_uid)
  end

  def follower_uids
    new_record? ? followerships.map(&:follower_uid) : followerships.pluck(:follower_uid)
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

  def self_searching?
    uid.to_i == user&.uid&.to_i
  end
end
