module Api
  module V1
    class EgotterFollowersController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def create
        if CreateEgotterFollowerWorker.new.create_record(current_user)
          render json: {message: t('.success', user: current_user.screen_name)}
        else
          render json: {message: t('.failure', user: current_user.screen_name)}
        end
      end
    end
  end
end
