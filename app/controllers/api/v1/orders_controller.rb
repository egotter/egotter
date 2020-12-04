module Api
  module V1
    class OrdersController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!

      def end_trial
        order = current_user.valid_order
        order.end_trial! if order.trial?
        send_message(order)
        render json: {message: t('.success_html', count: 5)}
      rescue => e
        logger.warn "#{self.class}##{__method__} #{e.inspect} user_id=#{current_user.id}"
        render json: {error: true, message: t('.fail')}, status: :unprocessable_entity
      end

      def cancel
        order = current_user.orders.find_by(id: params[:id])
        order.cancel! unless order.canceled?
        send_message(order)
        render json: {message: t('.success_html', count: 5)}
      rescue => e
        logger.warn "#{self.class}##{__method__} #{e.inspect} user_id=#{current_user.id}"
        render json: {error: true, message: t('.fail')}, status: :unprocessable_entity
      end

      private

      def send_message(order)
        message = "`#{Rails.env}:#{action_name}` user_id=#{current_user.id} order_id=#{order.id} device_type=#{request.device_type} referer=#{request.referer}"
        SendMessageToSlackWorker.perform_async(:orders, message)
      end
    end
  end
end
