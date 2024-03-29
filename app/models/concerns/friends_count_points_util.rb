require 'active_support/concern'

module FriendsCountPointsUtil
  extend ActiveSupport::Concern

  class_methods do
    def group_by_day(uid, start_time, end_time, padding)
      operator = detect_aggregation_operator
      records = where(uid: uid).where(created_at: start_time..end_time).
          select("gd_day(created_at, \"Asia/Tokyo\") date, #{operator}(value) val").group('date').to_a

      start_date = start_time.in_time_zone('Tokyo').to_date
      end_date = end_time.in_time_zone('Tokyo').to_date

      (start_date..end_date).each do |date|
        if records.none? { |r| r.date == date }
          records << Point.new(date: date, val: nil)
        end
      end

      records.sort_by!(&:date)

      if padding
        records.each.with_index do |record, i|
          if record.val.nil?
            prev_v = i > 0 ? records[i - 1].val : nil
            next_v = i < records.size - 1 ? records[i + 1].val : nil

            if prev_v && prev_v > 0 && next_v && next_v > 0
              record.val = (prev_v + next_v) / 2
            else
              record.val = prev_v || next_v || 0
            end
          end
        end
      end

      records
    end

    def detect_aggregation_operator
      [NewFriendsCountPoint, NewFollowersCountPoint, NewUnfriendsCountPoint, NewUnfollowersCountPoint].include?(self) ? 'sum' : 'avg'
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
