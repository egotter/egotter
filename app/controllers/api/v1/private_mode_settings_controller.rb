module Api
  module V1
    class PrivateModeSettingsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!
      before_action :has_valid_subscription!

      def create
        PrivateModeSetting.create!(user_id: current_user.id)
        render json: {status: 'ok'}
      end

      def destroy
        PrivateModeSetting.find_by(user_id: current_user.id).destroy!
        render json: {status: 'ok'}
      end
    end
  end
end
