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

    def many?(uid)
      where(uid: uid).size >= 2
    end

    def with_friends(uid, order:)
      where(uid: uid).where.not(friends_size: 0, followers_size: 0).order(created_at: order)
    end
  end

  DEFAULT_SECONDS = Rails.configuration.x.constants['twitter_user_recently_created']

  included do
  end

  def client
    @_client ||= (User.exists?(uid: uid) ? User.find_by(uid: uid).api_client : Bot.api_client)
  end

  def friendless?
    friends_size == 0 && followers_size == 0
  end

  def friend_uids
    if new_record?
      friends.map { |f| f.uid.to_i }
    else
      @_friend_uids ||= friends.pluck(:uid).map { |uid| uid.to_i }
    end
  end

  def follower_uids
    if new_record?
      followers.map { |f| f.uid.to_i }
    else
      @_follower_uids ||= followers.pluck(:uid).map { |uid| uid.to_i }
    end
  end

  def fresh?(attr = :updated_at, seconds: DEFAULT_SECONDS)
    Time.zone.now - send(attr) < seconds
  end
end
