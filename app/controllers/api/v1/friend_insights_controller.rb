module Api
  module V1
    class FriendInsightsController < ApplicationController
      include ApiRequestConcern

      before_action { set_insight }

      def profiles_count
        if @insight&.profiles_count&.any?
          words_count = @insight.sorted_profiles_count.map { |word, count| {word: word, count: count} }
          render json: {words_count: words_count}
        else
          CreateFriendInsightWorker.perform_async(@twitter_user.uid) unless from_crawler?
          render json: {message: t('.fail')}, status: :not_found
        end
      end

      def locations_count
        if @insight&.locations_count&.any?
          words_count = @insight.sorted_locations_count.map { |word, count| {word: word, count: count} }
          render json: {words_count: words_count}
        else
          CreateFriendInsightWorker.perform_async(@twitter_user.uid) unless from_crawler?
          render json: {message: t('.fail')}, status: :not_found
        end
      end

      def tweet_times
        if @insight&.tweet_times&.any?
          times = @insight.parsed_tweet_times
          tweets_per_hour = UsageStat::Misc.usage_stats_hour_series_data(times)
          drilldown = UsageStat::Misc.usage_stats_hour_drilldown_series(times)
          render json: {tweets_per_hour: tweets_per_hour, drilldown: drilldown}
        else
          CreateFriendInsightWorker.perform_async(@twitter_user.uid) unless from_crawler?
          render json: {message: t('.fail')}, status: :not_found
        end
      end

      private

      def set_insight
        @insight = FriendInsight.find_by(uid: @twitter_user.uid)
      end
    end
  end
end