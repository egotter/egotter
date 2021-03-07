module Api
  module V1
    class AccessStatsController < ApplicationController

      skip_before_action :verify_authenticity_token
      before_action :check_key, if: -> { Rails.env.production? }

      def index
        # count = GoogleAnalyticsClient.new.active_users
        count = CloudWatchClient.new.get_active_users
        render json: {active_users: count}
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
