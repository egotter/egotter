module Api
  module V1
    class DeleteTweetsNotificationsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        request = DeleteTweetsByArchiveRequest.create(user_id: current_user.id, archive_name: params[:filename], since_date: params[:since], until_date: params[:until])
        CreateDeleteTweetsUploadCompletedMessageWorker.perform_async(current_user.id, since: request.since_date, until: request.until_date)
        SendMessageToSlackWorker.perform_async(:monit_delete_tweets, "`Upload completed` user_id=#{current_user.id} request_id=#{request.id}")
        render json: {status: 'ok'}
      end
    end
  end
end
