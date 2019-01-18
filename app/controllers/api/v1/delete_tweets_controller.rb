module Api
  module V1
    class DeleteTweetsController < ApplicationController
      def delete
        if user_signed_in?
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
end
