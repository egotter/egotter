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

      def frequency
        %w(daily weekly monthly).include?(params[:frequency]) ? params[:frequency] : 'daily'
      end

      def now
        time_zone == 'utc' ? Time.zone.now : Time.zone.now.in_time_zone('Tokyo')
      end

      def duration
        %w(past_30_days past_90_days).include?(params[:duration]) ? params[:duration] : 'past_30_days'
      end

      def date_start
        send(duration).first
      end

      def date_end
        send(duration).last
      end

      def date_array
        apply_frequency(send(duration))
      end

      private

      def apply_frequency(days)
        num =
          case frequency
            when 'daily' then 1
            when 'weekly' then 14
            when 'monthly' then 30
          end
        days.map { |day| past_n_days(num, day) }
      end

      def past_30_days
        past_n_days(30)
      end

      def past_90_days
        past_n_days(90)
      end

      def past_n_days(num, now = nil)
        now = now() if now.nil?
        start = (now - num.days).beginning_of_day
        (num + 1).times.to_a.map { |i| start + i.days }
      end
    end
  end
end
