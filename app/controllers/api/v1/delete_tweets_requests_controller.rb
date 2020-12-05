module Api
  module V1
    class DeleteTweetsRequestsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        request = DeleteTweetsRequest.create!(user_id: current_user.id, tweet: params[:tweet] == 'true')
        DeleteTweetsWorker.perform_async(request.id, user_id: current_user.id)
        SendDeleteTweetsStartedWorker.perform_async(request.id, user_id: current_user.id)
        SendDeleteTweetsNotFinishedWorker.perform_in(30.minutes, request.id, user_id: current_user.id)

        track_event('Delete tweets', request_id: request.id)

        render json: {message: t('.success')}
      end
    end
  end
end
