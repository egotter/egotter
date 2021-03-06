module Api
  module V1
    class AccessStatsController < ApplicationController

      skip_before_action :verify_authenticity_token
      before_action :check_key

      def index
        render json: {active_users: GoogleAnalyticsClient.new.active_users.to_i}
      end

      private

      def check_key
        unless params['key'] == ENV['STATS_API_KEY']
          head :forbidden
        end
      end
    end
  end
end
