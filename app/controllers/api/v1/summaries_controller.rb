module Api
  module V1
    class SummariesController < ApplicationController
      include ApiRequestConcern

      def show
        render json: @twitter_user.to_summary
      end
    end
  end
end
