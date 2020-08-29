module Api
  module V1
    class FollowerInsightsController < ApplicationController
      include Concerns::ApiRequestConcern

      before_action { set_insight }

      def profiles_count
        if @insight
          words_count = @insight.profiles_count.sort_by { |_, v| -v }.map { |word, count| {word: word, count: count} }
          render json: {words_count: words_count}
        else
          CreateFollowerInsightWorker.perform_async(@twitter_user.uid)
          head :not_found
        end
      end

      def locations_count
        if @insight
          words_count = @insight.locations_count.sort_by { |_, v| -v }.map { |word, count| {word: word, count: count} }
          render json: {words_count: words_count}
        else
          CreateFollowerInsightWorker.perform_async(@twitter_user.uid)
          head :not_found
        end
      end

      private

      def set_insight
        @insight = FollowerInsight.find_by(uid: @twitter_user.uid)
      end
    end
  end
end