module Api
  module V1
    class UsersController < ApplicationController

      skip_before_action :verify_authenticity_token, only: :update_instance_id

      def update_instance_id
        if params[:uid].present? && params[:access_token].present? && params[:instance_id].present? &&
            (user = User.find_by(uid: params[:uid], token: params[:access_token]))
          render json: {uid: user.uid, found: true}
        else
          render json: {found: false}, status: :not_found
        end
      end
    end
  end
end
