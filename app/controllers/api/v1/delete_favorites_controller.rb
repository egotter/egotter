module Api
  module V1
    class DeleteFavoritesController < ApplicationController

      before_action :require_login!

      before_action do
        unless current_user.authorized?
          render json: {message: unauthorized_message(current_user.screen_name)}, status: :unauthorized
        end
      end

      def destroy
        request = DeleteFavoritesRequest.create!(user_id: current_user.id, tweet: params[:tweet] == 'true')
        jid = DeleteFavoritesWorker.perform_async(request.id, user_id: current_user.id)

        track_event('Delete favorites', request_id: request.id)
        SendDeleteFavoritesStartedWorker.perform_async(request.id, user_id: current_user.id)
        SendDeleteFavoritesNotFinishedWorker.perform_in(30.minutes, request.id, user_id: current_user.id)

        render json: {jid: jid}
      end
    end
  end
end
