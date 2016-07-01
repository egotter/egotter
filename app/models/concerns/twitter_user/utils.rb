require 'active_support/concern'

module Concerns::TwitterUser::Utils
  extend ActiveSupport::Concern

  class_methods do
    def has_more_than_two_records?(uid, user_id)
      where(uid: uid, user_id: user_id).limit(2).pluck(:id).size >= 2
    end
  end

  included do
    def self.oldest(user, user_id)
      user.kind_of?(Integer) ?
        order(created_at: :asc).find_by(uid: user.to_i, user_id: user_id) : order(created_at: :asc).find_by(screen_name: user.to_s, user_id: user_id)
    end

    def self.latest(user, user_id)
      user.kind_of?(Integer) ?
        order(created_at: :desc).find_by(uid: user.to_i, user_id: user_id) : order(created_at: :desc).find_by(screen_name: user.to_s, user_id: user_id)
    end

    DEFAULT_SECONDS = Rails.configuration.x.constants['twitter_user_recently_created_threshold']

    def recently_created?(seconds = DEFAULT_SECONDS)
      Time.zone.now.to_i - created_at.to_i < seconds
    end

    def recently_updated?(seconds = DEFAULT_SECONDS)
      Time.zone.now.to_i - updated_at.to_i < seconds
    end

    def oldest_me
      TwitterUser.oldest(__uid_i, user_id)
    end

    def latest_me
      TwitterUser.latest(__uid_i, user_id)
    end

    def search_and_touch
      update!(search_count: search_count + 1)
    rescue => e
      logger.error "#{self.class}##{__method__} #{e.class} #{e.message}"
    end

    def update_and_touch
      update!(update_count: update_count + 1)
    rescue => e
      logger.error "#{self.class}##{__method__} #{e.class} #{e.message}"
    end
  end
end