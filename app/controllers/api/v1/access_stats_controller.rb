module Api
  module V1
    class AccessStatsController < ApplicationController

      skip_before_action :verify_authenticity_token
      before_action :check_key, if: -> { Rails.env.production? }

      def index
        # count = GoogleAnalyticsClient.new.active_users
        client = CloudWatchClient.new

        render json: {
            total: client.get_active_users.to_i,
            mobile: client.get_active_users('MOBILE').to_i,
            desktop: client.get_active_users('DESKTOP').to_i,
            active_users: client.get_active_users.to_i,
        }
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
