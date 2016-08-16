module KpiAdmin
  module Kpis
    module DurationHelper
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
        send(duration, :start)
      end

      def date_end
        send(duration, :end)
      end

      private

      def past_30_days(start_or_end)
        {start: (now - 30.days).beginning_of_day, end: now.end_of_day}[start_or_end]
      end

      def past_90_days(start_or_end)
        {start: (now - 90.days).beginning_of_day, end: now.end_of_day}[start_or_end]
      end
    end
  end
end
