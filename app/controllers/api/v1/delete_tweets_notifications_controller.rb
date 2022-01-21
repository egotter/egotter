module Api
  module V1
    class DeleteTweetsNotificationsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        request = DeleteTweetsByArchiveRequest.create(user_id: current_user.id, archive_name: params[:filename], since_date: validated_since, until_date: validated_until)
        CreateDeleteTweetsUploadCompletedMessageWorker.perform_async(current_user.id, since: request.since_date, until: request.until_date)
        SendMessageToSlackWorker.perform_async(:monit_delete_tweets, "`Upload completed` user_id=#{current_user.id} request_id=#{request.id}")
        render json: {status: 'ok'}
      end
      private

      DATE_REGEXP = /\A\d{4}-\d{2}-\d{2}\z/

      def validated_since
        if params[:since]&.match?(DATE_REGEXP)
          "#{params[:since]} 00:00:00 JST"
        end
      end

      def validated_until
        if params[:until]&.match?(DATE_REGEXP)
          "#{params[:until]} 00:00:00 JST"
        end
      end
    end
  end
end
