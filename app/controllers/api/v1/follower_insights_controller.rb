module Api
  module V1
    class FollowerInsightsController < ApplicationController
      include ApiRequestConcern

      before_action { set_insight }

      def profiles_count
        if @insight&.profiles_count&.any?
          words_count = @insight.profiles_count.sort_by { |_, v| -v }.map { |word, count| {word: word, count: count} }
          render json: {words_count: words_count}
        else
          CreateFollowerInsightWorker.perform_async(@twitter_user.uid) unless from_crawler?
          render json: {message: t('.fail')}, status: :not_found
        end
      end

      def locations_count
        if @insight&.locations_count&.any?
          words_count = @insight.locations_count.sort_by { |_, v| -v }.map { |word, count| {word: word, count: count} }
          render json: {words_count: words_count}
        else
          CreateFollowerInsightWorker.perform_async(@twitter_user.uid) unless from_crawler?
          render json: {message: t('.fail')}, status: :not_found
        end
      end

      def tweet_times
        if @insight&.tweet_times&.any?
          times = @insight.tweet_times.map { |t| Time.zone.at(t) }
          tweets_per_hour = UsageStat::Misc.usage_stats_hour_series_data(times)
          render json: {tweets_per_hour: tweets_per_hour}
        else
          CreateFollowerInsightWorker.perform_async(@twitter_user.uid) unless from_crawler?
          render json: {message: t('.fail')}, status: :not_found
        end
      end

      private

      def set_insight
        @insight = FollowerInsight.find_by(uid: @twitter_user.uid)
      end
    end
  end
end