module Api
  module V1
    class SearchRequestsController < ApplicationController

      before_action { valid_screen_name?(params[:screen_name]) }

      def show
        render json: {found: SearchRequestCache.exists?(params[:screen_name])}
      end
    end
  end
end
