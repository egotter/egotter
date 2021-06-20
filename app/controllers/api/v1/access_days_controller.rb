module Api
  module V1
    class AccessDaysController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        CreateAccessDayWorker.new.create_record(current_user)
        render json: {message: t('.success', user: current_user.screen_name)}
      end
    end
  end
end
