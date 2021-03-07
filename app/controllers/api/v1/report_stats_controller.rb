module Api
  module V1
    class ReportStatsController < ApplicationController

      skip_before_action :verify_authenticity_token
      before_action :check_key, if: -> { Rails.env.production? }

      def index
        response = %w(report_low report_high CreateReportTwitterUserWorker).map do |name|
          [name, Sidekiq::Queue.new(name).size]
        end.to_h
        render json: response
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
