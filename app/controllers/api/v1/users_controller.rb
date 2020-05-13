module Api
  module V1
    class UsersController < ApplicationController

      skip_before_action :verify_authenticity_token, only: %i(update_instance_id update_device_token)

      # Android
      def update_instance_id
        if verified_android_request?
          @user.credential_token.update!(instance_id: params[:instance_id])
          jid = enqueue_create_periodic_report_job(@user)
          render json: build_android_response(@user, jid)
        else
          render json: {found: false}, status: :not_found
        end
      rescue => e
        logger.warn "#{__method__} #{e.inspect} params=#{params.inspect}"
        render json: {found: false}, status: :internal_server_error
      end

      # iPhone
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

      private

      # NOTICE The name #verified_request? conflicts with an existing method in Rails.
      def verified_android_request?
        params[:uid].present? && params[:access_token].present? && params[:instance_id].present? &&
            (@user = User.find_by(uid: params[:uid], token: params[:access_token]))
      end

      def enqueue_create_periodic_report_job(user)
        request = CreatePeriodicReportRequest.create(user_id: user.id)
        CreateAndroidRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id, requested_by: 'android_app')
      end

      def build_android_response(user, jid)
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

        response
      end


    end
  end
end
