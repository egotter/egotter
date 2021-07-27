module Api
  module V1
    class OrdersController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :has_valid_subscription!, except: :index

      after_action :track_order_activity

      INTERVAL = 5

      def index
        if (subscription = current_user.has_valid_subscription?)
          message = t('.success_html', count: INTERVAL)
        else
          message = t('.fail_html', count: INTERVAL)
        end
        render json: {message: message, subscription: subscription}
      end

      def end_trial
        order = current_user.valid_order
        order.end_trial! if order.trial?
        send_message(order)
        render json: {message: t('.success_html'), interval: INTERVAL}
      rescue => e
        logger.warn "#{self.class}##{__method__} #{e.inspect} user_id=#{current_user.id}"
        render json: {error: true, message: t('.fail')}, status: :unprocessable_entity
      end

      def cancel
        order = current_user.orders.find_by(id: params[:id])
        order.cancel!('user') unless order.canceled?
        send_message(order)
        render json: {message: t('.success_html', count: INTERVAL), interval: INTERVAL}
      rescue => e
        logger.warn "#{self.class}##{__method__} #{e.inspect} user_id=#{current_user.id}"
        render json: {error: true, message: t('.fail')}, status: :unprocessable_entity
      end

      private

      def send_message(order)
        message = "`#{action_name}` user_id=#{current_user.id} order_id=#{order.id} device_type=#{request.device_type} referer=#{request.referer}"
        SlackMessage.create(channel: 'orders', message: message)
        SendMessageToSlackWorker.perform_async(:orders, "`#{Rails.env}` #{message}")
      end
    end
  end
end
