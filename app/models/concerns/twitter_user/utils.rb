require 'active_support/concern'

module Concerns::TwitterUser::Utils
  extend ActiveSupport::Concern

  class_methods do
    def latest(uid)
      order(created_at: :desc).find_by(uid: uid)
    end

    def many?(uid)
      where(uid: uid).size >= 2
    end

    def with_friends(uid, order:)
      where(uid: uid).order(created_at: order).reject { |tu| tu.friendless? }
    end
  end

  DEFAULT_SECONDS = Rails.configuration.x.constants['twitter_user_recently_created']

  included do
  end

  def client
    @_client ||= (User.exists?(uid: uid) ? User.find_by(uid: uid).api_client : Bot.api_client)
  end

  def friendless?
    friends.empty? && followers.empty?
  end

  def friend_uids
    new_record? ? friends.map { |f| f.uid.to_i } : friends.pluck(:uid).map { |uid| uid.to_i }
  end

  def follower_uids
    new_record? ? followers.map { |f| f.uid.to_i } : followers.pluck(:uid).map { |uid| uid.to_i }
  end

  def fresh?(attr = :updated_at, seconds: DEFAULT_SECONDS)
    Time.zone.now - send(attr) < seconds
  end
end
