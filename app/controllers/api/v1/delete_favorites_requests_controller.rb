module Api
  module V1
    class DeleteFavoritesRequestsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        request = DeleteFavoritesRequest.create!(
            user_id: current_user.id,
            since_date: validated_since,
            until_date: validated_until,
            send_dm: params[:dm] == 'true',
            tweet: params[:tweet] == 'true',
        )

        DeleteFavoritesWorker.perform_async(request.id, user_id: current_user.id)
        SendDeleteFavoritesStartedWorker.perform_async(request.id, user_id: current_user.id)
        SendDeleteFavoritesNotFinishedWorker.perform_in(30.minutes, request.id, user_id: current_user.id)

        track_event('Delete favorites', request_id: request.id)

        render json: {message: t('.success')}
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
    end
  end
end
