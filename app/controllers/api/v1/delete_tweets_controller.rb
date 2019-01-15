module Api
  module V1
    class DeleteTweetsController < ApplicationController
      def delete
        if user_signed_in?
          user = current_user
          jid =
              DeleteTweetsWorker.perform_async(
                  session_id: fingerprint,
                  user_id: user.id,
                  uid: user.uid,
                  screen_name: user.screen_name
              )
          render json: {jid: jid}
        end
      end
    end
  end
end
