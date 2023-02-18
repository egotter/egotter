module Api
  module V1
    class OrdersController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :has_valid_subscription!, except: :index

      after_action { track_page_order_activity(order_id: params[:id]) }

      INTERVAL = 5

      def index
        if current_user.has_valid_subscription?
          render json: {message: t('.success_html'), subscription: true, interval: INTERVAL}
        else
          render json: {message: t('.fail_html'), subscription: false, interval: INTERVAL}
        end
      end

      def end_trial
        order = current_user.valid_order
        order.end_trial! if order.trial?
        send_slack_message(order)
        render json: {message: t('.success_html'), interval: INTERVAL}
      rescue => e
        Airbag.warn "#{self.class}##{__method__} #{e.inspect} user_id=#{current_user.id}"
        render json: {error: true, message: t('.fail')}, status: :unprocessable_entity
      end

      def cancel
        order = current_user.orders.find_by(id: params[:id])
        order.cancel!('user') unless order.canceled?
        send_slack_message(order)
        render json: {message: t('.success_html', count: INTERVAL), interval: INTERVAL}
      rescue => e
        Airbag.warn "#{self.class}##{__method__} #{e.inspect} user_id=#{current_user.id}"
        render json: {error: true, message: t('.fail')}, status: :unprocessable_entity
      end

      private

      def send_slack_message(order)
        channel = tracking_channel
        props = {
            user_id: current_user.id,
            order_id: order.id,
            via: params[:via],
        }
        SendMessageToSlackWorker.perform_async(channel, "`#{Rails.env}` #{props}")
      end

      def tracking_channel
        case action_name
        when 'end_trial'
          'orders_end_trial'
        when 'cancel'
          'orders_cancel'
        else
          'orders'
        end
      end
    end
  end
end
