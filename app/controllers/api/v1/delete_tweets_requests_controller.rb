module Api
  module V1
    class DeleteTweetsRequestsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        request = DeleteTweetsRequest.create!(
            user_id: current_user.id,
            since_date: validated_since,
            until_date: validated_until,
            send_dm: params[:dm] == 'true',
            tweet: params[:tweet] == 'true',
        )

        # DeleteTweetsWorker.perform_async(request.id, user_id: current_user.id)
        # SendDeleteTweetsStartedWorker.perform_async(request.id, user_id: current_user.id)
        SendDeleteTweetsNotFinishedWorker.perform_in(30.minutes, request.id, user_id: current_user.id)

        track_event('Delete tweets', request_id: request.id)

        token_message = I18n.t('short_messages.delete_tweets_token', token: request.request_token)
        expiry = MessageHelper.distance_of_time_in_words(DeleteTweetsRequest::REQUEST_TOKEN_EXPIRY)
        direct_message_url = MessageHelper.direct_message_url(User::EGOTTER_UID, token_message)
        render json: {url: direct_message_url, message: t('.success_html', expiry: expiry, url: direct_message_url, message: token_message)}
      end

      private

      DATE_REGEXP = /\A\d{4}-\d{2}-\d{2}\z/

      def validated_since
        if params[:since]&.match?(DATE_REGEXP)
          Time.zone.parse("#{params[:since]} 00:00:00 JST")
        end
      end

      def validated_until
        if params[:until]&.match?(DATE_REGEXP)
          Time.zone.parse("#{params[:until]} 23:59:59 JST")
        end
      end

      module MessageHelper
        # direct_message_url
        extend TwitterHelper

        # distance_of_time_in_words
        extend ActionView::Helpers::DateHelper
      end
    end
  end
end
