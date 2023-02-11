require 'active_support/concern'

module TwitterUserQueryMethods
  extend ActiveSupport::Concern

  DEFAULT_TIMESTAMP_DELAY = 3.seconds

  class_methods do
    def latest_by(condition)
      order(created_at: :desc).find_by(condition)
    end

    def with_delay
      where('created_at < ?', DEFAULT_TIMESTAMP_DELAY.ago)
    end
  end

  # TODO Decrease limit
  def unfriends_target(limit = 50)
    TwitterUser.select(:id, :uid, :screen_name, :created_at).
        creation_completed.
        where(uid: uid).
        where('created_at <= ?', created_at).
        order(created_at: :desc).
        limit(limit).
        reverse
  end

  included do
    scope :creation_completed, -> do
      where.not('friends_size = 0 and followers_size = 0')
    end
  end
end
