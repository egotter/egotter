module Api
  module V1
    class DeleteTweetsNotificationsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        SendMessageToSlackWorker.perform_async(:delete_tweets, "`Upload completed` user_id=#{current_user.id} screen_name=#{current_user.screen_name}")

        CreateDeleteTweetsUploadCompletedMessageWorker.perform_async(current_user.id, since: validated_since, until: validated_until)
        render json: {status: 'ok'}
      end

      private

      DATE_REGEXP = /\A\d{4}-\d{2}-\d{2}\z/

      def validated_since
        if params[:since]&.match?(DATE_REGEXP)
          params[:since]
        end
      end

      def validated_until
        if params[:until]&.match?(DATE_REGEXP)
          params[:until]
        end
      end
    end
  end
end
