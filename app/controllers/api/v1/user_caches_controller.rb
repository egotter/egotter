module Api
  module V1
    class UserCachesController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!
      before_action :fail_if_already_requested

      def destroy
        request = ResetCacheRequest.create!(
            session_id: egotter_visit_id,
            user_id: current_user.id,
            finished_at: Time.zone.now
        )
        # jid = ResetCacheWorker.perform_async(request.id)
        SendResetCacheStartedWorker.perform_async(request.id)
        render json: {message: t('.success')}
      end

      private

      def fail_if_already_requested
        if current_user.reset_cache_requests.not_finished.exists?
          render json: {message: t('.destroy.fail')}, status: :bad_request
        end
      end
    end
  end
end
