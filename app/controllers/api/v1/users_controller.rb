module Api
  module V1
    class UsersController < ApplicationController

      skip_before_action :verify_authenticity_token, only: :update_instance_id

      def update_instance_id
        if params[:uid].present? && params[:access_token].present? && params[:instance_id].present? &&
            (user = User.find_by(uid: params[:uid], token: params[:access_token]))

          user.credential_token.update!(instance_id: params[:instance_id])

          request = CreatePromptReportRequest.create(user_id: user.id, skip_error_check: true)
          CreatePromptReportWorker.perform_async(request.id, requested_by: 'android_app')

          render json: {uid: user.uid, screen_name: user.screen_name, version_code: ENV['ANDROID_VERSION_CODE'], found: true}
        else
          render json: {found: false}, status: :not_found
        end
      end
    end
  end
end
