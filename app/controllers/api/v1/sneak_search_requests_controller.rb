module Api
  module V1
    class SneakSearchRequestsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!
      before_action :has_valid_subscription!

      def create
        SneakSearchRequest.create!(user_id: current_user.id)
        render json: {status: 'ok'}
      end

      def destroy
        SneakSearchRequest.find_by(user_id: current_user.id).destroy!
        render json: {status: 'ok'}
      end
    end
  end
end
