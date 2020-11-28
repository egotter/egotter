module Api
  module V1
    class BotsController < ApplicationController

      skip_before_action :verify_authenticity_token

      def invalidate_expired_credentials
        InvalidateExpiredCredentialsWorker.perform_async
        render json: {status: 'ok'}
      end
    end
  end
end
