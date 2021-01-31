module Api
  module V1
    class ReportStatsController < ApplicationController

      skip_before_action :verify_authenticity_token
      before_action :check_key

      def index
        render json: %w(report_low report_high).map { |name| [name, Sidekiq::Queue.new(name).size] }.to_h
      end

      private

      def check_key
        unless params['key'] == ENV['REPORT_STATS_KEY']
          head :forbidden
        end
      end
    end
  end
end
