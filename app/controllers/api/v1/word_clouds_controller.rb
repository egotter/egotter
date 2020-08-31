module Api
  module V1
    class WordCloudsController < ApplicationController
      include Concerns::ApiRequestConcern

      before_action { set_stat }

      def show
        if @stat&.words_count
          words_count = @stat.words_count.sort_by { |_, v| -v }.map { |word, count| {word: word, count: count} }
          render json: {words_count: words_count}
        else
          UpdateUsageStatWorker.perform_async(@twitter_user.uid, user_id: @twitter_user.user_id) unless from_crawler?
          head :not_found
        end
      end

      private

      def set_stat
        @stat = UsageStat.find_by(uid: @twitter_user.uid)
      end
    end
  end
end