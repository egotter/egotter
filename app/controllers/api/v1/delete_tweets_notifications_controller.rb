module Api
  module V1
    class DeleteTweetsNotificationsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        SendMessageToSlackWorker.perform_async(:delete_tweets, "`Upload completed` user_id=#{current_user.id} screen_name=#{current_user.screen_name}")
        CreateDeleteTweetsUploadCompletedMessageWorker.perform_async(current_user.id)
        render json: {status: 'ok'}
      end
    end
  end
end
