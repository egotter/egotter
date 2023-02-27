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

        if order.trial?
          order.end_trial!
          send_message('Success', order_id: order.id)
          render json: {message: t('.success_html'), interval: INTERVAL}
        else
          send_message('Not trialing', order_id: order.id)
          render json: {message: t('.not_trial_html')}, status: :bad_request
        end
      rescue => e
        Airbag.exception e, user_id: current_user.id
        render json: {error: true, message: t('.fail_html')}, status: :unprocessable_entity
      end

      def cancel
        order = current_user.orders.find_by(id: params[:id])

        if order.canceled?
          send_message('Already canceled', order_id: order.id)
          render json: {message: t('.already_canceled')}, status: :bad_request
        else
          order.cancel!('user')
          send_message('Success', order_id: order.id)
          render json: {message: t('.success_html'), interval: INTERVAL}
        end
      rescue => e
        Airbag.exception e, user_id: current_user.id
        render json: {error: true, message: t('.fail_html')}, status: :unprocessable_entity
      end

      private

      def send_message(message, order_id: nil)
        props = {api: true, user_id: current_user.id, order_id: order_id, via: params[:via]}.compact
        SendOrderMessageToSlackWorker.perform_async(tracking_channel, "`#{Rails.env}` #{message} #{props}")
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
