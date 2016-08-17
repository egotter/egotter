module KpiAdmin
  module Kpis
    module DurationHelper
      def to_msec_unixtime(date)
        date.in_time_zone(city).to_i * 1000
      end

      def city
        case time_zone
          when 'utc' then 'UTC'
          when 'jst' then 'Tokyo'
        end
      end

      def time_zone
        %w(utc jst).include?(params[:time_zone]) ? params[:time_zone] : 'utc'
      end

      def now
        time_zone == 'utc' ? Time.zone.now : Time.zone.now.in_time_zone('Tokyo')
      end

      def duration
        %w(past_30_days past_90_days).include?(params[:duration]) ? params[:duration] : 'past_30_days'
      end

      def date_start
        send(duration, 0)
      end

      def date_end
        send(duration, -1)
      end

      def date_array
        send(duration)
      end

      private

      def past_30_days(index = nil)
        past_n_days(30, index)
      end

      def past_90_days(index = nil)
        past_n_days(90, index)
      end

      def past_n_days(num, index)
        start = (now - num.days).beginning_of_day
        result = num.times.to_a.map { |i| start + i.days }
        index ? result[index] : result
      end
    end
  end
end
