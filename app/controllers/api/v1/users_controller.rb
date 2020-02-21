module Api
  module V1
    class UsersController < ApplicationController

      skip_before_action :verify_authenticity_token, only: %i(update_instance_id update_device_token)

      def update_instance_id
        if params[:uid].present? && params[:access_token].present? && params[:instance_id].present? &&
            (user = User.find_by(uid: params[:uid], token: params[:access_token]))

          user.credential_token.update!(instance_id: params[:instance_id])

          request = CreatePromptReportRequest.create(user_id: user.id, skip_error_check: true)
          jid = CreatePromptReportWorker.perform_async(request.id, requested_by: 'android_app')

          response = {
              uid: user.uid,
              screen_name: user.screen_name,
              version_code: ENV['ANDROID_VERSION_CODE'],
              found: true,
              jid: jid
          }

          if (twitter_user = TwitterUser.latest_by(uid: user.uid))
            response.merge!(twitter_user.summary_counts)
          end

          render json: response
        else
          render json: {found: false}, status: :not_found
        end
      end

      def update_device_token
        if params[:uid].present? && params[:access_token].present? && params[:device_token].present? &&
            (user = User.find_by(uid: params[:uid], token: params[:access_token]))

          user.credential_token.update!(device_token: params[:device_token])

          request = CreatePromptReportRequest.create(user_id: user.id, skip_error_check: true)
          jid = CreatePromptReportWorker.perform_async(request.id, requested_by: 'ios_app')

          response = {
              uid: user.uid,
              screen_name: user.screen_name,
              found: true,
              jid: jid
          }

          if (twitter_user = TwitterUser.latest_by(uid: user.uid))
            response.merge!(twitter_user.summary_counts)
          end

          render json: response
        else
          render json: {found: false}, status: :not_found
        end
      end
    end
  end
end
