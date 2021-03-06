module Api
  module V1
    class NotFoundUsersController < ApplicationController

      skip_before_action :verify_authenticity_token

      def delete
        DeleteNotFoundUsersWorker.perform_async
      end
    end
  end
end
