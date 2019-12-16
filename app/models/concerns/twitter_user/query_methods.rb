require 'active_support/concern'

module Concerns::TwitterUser::QueryMethods
  extend ActiveSupport::Concern

  class_methods do
    def latest_by(condition)
      order(created_at: :desc).find_by(condition)
    end

    def with_delay
      where('created_at < ?', 3.seconds.ago)
    end
  end

  included do
    scope :creation_completed, -> do
      where.not('friends_size = 0 and followers_size = 0')
    end
  end
end
