module Api
  module V1
    class DeleteTweetsHistoriesController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def index
        requests = [
            DeleteTweetsRequest.where(user_id: current_user.id).order(created_at: :desc).limit(10),
            DeleteTweetsBySearchRequest.where(user_id: current_user.id).order(created_at: :desc).limit(10),
            DeleteTweetsByArchiveRequest.where(user_id: current_user.id).order(created_at: :desc).limit(10)
        ].flatten.sort_by { |r| -r.created_at.to_i }.take(10)

        render json: {requests: to_json(requests), error_message: extract_error_message(requests)}
      end

      private

      def to_json(requests)
        requests.map do |req|
          {
              type: request_type(req.class),
              reservations_count: req.reservations_count,
              deletions_count: req.respond_to?(:deletions_count) ? req.deletions_count : req.destroy_count,
              created_at: request_time(req.created_at),

          }
        end
      end

      def extract_error_message(requests)
        if requests.any? && requests[0].respond_to?(:error_message) && requests[0].error_message&.include?('expired')
          t('.index.error_message_html', url: sign_in_path(redirect_path: delete_tweets_mypage_path, via: current_via('error')))
        end
      end

      def request_type(klass)
        if klass == DeleteTweetsRequest
          t('.index.request_types.default')
        elsif klass == DeleteTweetsBySearchRequest
          t('.index.request_types.search')
        elsif klass == DeleteTweetsByArchiveRequest
          t('.index.request_types.archive')
        else
          t('.index.request_types.default')
        end
      end

      def request_time(time)
        time = time.in_time_zone('Tokyo')
        if time.today?
          l(time, format: :delete_tweets_short)
        else
          l(time, format: :delete_tweets_long)
        end
      end
    end
  end
end
