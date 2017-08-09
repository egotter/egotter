require 'active_support/concern'

module Concerns::TwitterUser::Utils
  extend ActiveSupport::Concern

  class_methods do
    def latest(uid)
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

  def friendless?
    friends_size == 0 && followers_size == 0
  end

  def friend_uids
    new_record? ? friendships.map(&:friend_uid) : friendships.pluck(:friend_uid)
  end

  def follower_uids
    new_record? ? followerships.map(&:follower_uid) : followerships.pluck(:follower_uid)
  end

  def latest?
    id == TwitterUser.latest(uid).id
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

  def relationships_cache_created?
    created_at < 10.minutes.ago
  end
end
