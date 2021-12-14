require 'active_support/concern'

module FriendsCountPointsUtil
  extend ActiveSupport::Concern

  included do
    scope :time_within, -> (time, duration) do
      where(created_at: (time - duration)..(time + duration))
    end
  end

  class_methods do
    def group_by_day(uid, start_time, end_time)
      records = where(uid: uid).where(created_at: start_time..end_time).
          select('gd_day(created_at, "Asia/Tokyo") date, avg(value) val').group('date').to_a

      start_date = start_time.in_time_zone('Tokyo').to_date
      end_date = end_time.in_time_zone('Tokyo').to_date

      (start_date..end_date).each do |date|
        if records.none? { |r| r.date == date }
          records << Point.new(date: date, val: nil)
        end
      end

      records.sort_by!(&:date)

      # records.each.with_index do |record, i|
      #   if record.val == -1
      #     prev_v = i > 0 ? records[i - 1].val : 0
      #     next_v = i < records.size - 1 ? records[i + 1].val : 0
      #     record.val = (prev_v + next_v) / 2
      #   end
      # end

      records
    end
  end

  class Point
    attr_accessor :date, :val

    def initialize(date:, val:)
      @date = date
      @val = val
    end
  end
end
