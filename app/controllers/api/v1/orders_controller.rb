module Api
  module V1
    class OrdersController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def end_trial
        order = current_user.valid_order
        if order.trial?
          order.end_trial!
        end
        send_message(order)
        render json: {message: t('.success')}
      rescue => e
        logger.warn "#{self.class}##{__method__} #{e.inspect} user_id=#{current_user.id}"
        render json: {error: true, message: t('.fail')}, status: :unprocessable_entity
      end

      def cancel
        order = current_user.orders.find_by(id: params[:id])
        unless order.canceled?
          order.cancel!
        end
        send_message(order)
        render json: {message: t('.success')}
      rescue => e
        logger.warn "#{self.class}##{__method__} #{e.inspect} user_id=#{current_user.id}"
        render json: {error: true, message: t('.fail')}, status: :unprocessable_entity
      end

      private

      def send_message(order)
        message = "`#{Rails.env}:#{action_name}` user_id=#{current_user.id} order_id=#{order.id}"
        SendMessageToSlackWorker.perform_async(:orders, message)
      end
    end
  end
end
