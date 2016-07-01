require 'active_support/concern'

module Concerns::TwitterUser::Utils
  extend ActiveSupport::Concern

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
  end
end