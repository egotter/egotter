module Api
  module V1
    class FriendInsightsController < ApplicationController
      include Concerns::ApiRequestConcern

      def profiles_count
        if (insight = FriendInsight.find_by(uid: @twitter_user.uid))
          words_count = insight.profiles_count.sort_by { |_, v| -v }.map { |word, count| {word: word, count: count} }
          render json: {words_count: words_count}
        else
          head :not_found
        end
      end

      def locations_count
        if (insight = FriendInsight.find_by(uid: @twitter_user.uid))
          words_count = insight.locations_count.sort_by { |_, v| -v }.map { |word, count| {word: word, count: count} }
          render json: {words_count: words_count}
        else
          head :not_found
        end
      end
    end
  end
end