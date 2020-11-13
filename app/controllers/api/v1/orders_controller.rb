module Api
  module V1
    class OrdersController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def end_trial
        current_user.valid_order.end_trial!
        render json: {message: t('.success')}
      rescue => e
        logger.warn "#{self.class}##{__method__} #{e.inspect} user_id=#{current_user.id}"
        render json: {error: true, message: t('.fail')}, status: :unprocessable_entity
      end
    end
  end
end
