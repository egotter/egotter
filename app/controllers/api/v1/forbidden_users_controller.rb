module Api
  module V1
    class ForbiddenUsersController < ApplicationController

      skip_before_action :verify_authenticity_token

      def delete
        DeleteForbiddenUsersWorker.perform_async
        render json: {status: 'ok'}
      end
    end
  end
end
