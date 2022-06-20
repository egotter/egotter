module Api
  module V1
    class DeleteTweetsErrorNotificationsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        SendMessageToSlackWorker.perform_async(:monit_delete_tweets_error, "#{params[:message]} props=#{params[:props]} user_id=#{current_user.id}")
        head :ok
      end
    end
  end
end
