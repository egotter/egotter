module Api
  module V1
    class TrendsController < ApplicationController

      layout false

      before_action { head :forbidden unless request.headers['HTTP_X_CSRF_TOKEN'] }
      before_action { set_trend }

      def words_count
        render json: {words_count: words_count_chart_format(@trend.words_count)}
      end

      def times_count
        render json: {times_count: times_count_chart_format(@trend.times_count, @trend.time)}
      end

      private

      def words_count_chart_format(words_count)
        (words_count || []).map { |w, c| {word: w, count: c} }
      end

      def times_count_chart_format(times_count, trend_time, padding: true)
        return [] if times_count.blank?

        if padding
          time = trend_time - 1.day

          while time < trend_time do
            label_time = time.change(second: 0)
            if times_count.none? { |t, _| t == label_time.to_i }
              times_count << [label_time.to_i, 0]
            end
            time += 1.minute
          end
        end

        times_count.sort_by { |t, _| t }.map { |t, c| [t * 1000, c] }
      end

      def set_trend
        @trend = Trend.japan.latest_trends.top_n(3).find_by(id: params[:id])
      end
    end
  end
end