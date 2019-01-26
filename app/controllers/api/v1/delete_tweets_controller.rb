module Api
  module V1
    class DeleteTweetsController < ApplicationController
      before_action :require_login!

      def delete
        jid =
            DeleteTweetsWorker.perform_async(
                session_id: fingerprint,
                user_id: current_user.id
            )
        render json: {jid: jid}
      end
    end
  end
end
