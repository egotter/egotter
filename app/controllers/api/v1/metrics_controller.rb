# TODO Remove later
module Api
  module V1
    class MetricsController < ApplicationController

      skip_before_action :verify_authenticity_token

      def send_to_cloudwatch
        SendMetricsToCloudWatchWorker.perform_async
        render json: {status: 'ok'}
      end
    end
  end
end
