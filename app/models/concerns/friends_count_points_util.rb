require 'active_support/concern'

module FriendsCountPointsUtil
  extend ActiveSupport::Concern

  included do
    scope :time_within, -> (time, duration) do
      where(created_at: (time - duration)..(time + duration))
    end
  end

  class_methods do
    def group_by_day(uid, limit)
      where(uid: uid).where(created_at: limit.days.ago..Time.zone.now).
          select('gd_day(created_at, "Asia/Tokyo") date, avg(value) val').group('date')
    end
  end
end
