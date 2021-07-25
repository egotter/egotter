module Api
  module V1
    class CheckoutSessionsController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :doesnt_have_valid_subscription!

      after_action :track_event
      after_action :send_message

      def create
        @session = StripeCheckoutSession.create(current_user)
        render json: {session_id: @session.id}
      end

      private

      def log_event
        if @session
          props = {id: @session.id, customer: @session.customer, metadata: @session.metadata, referer: request.referer.to_s.truncate(200)}
          track_order_activity(checkout_session: props)
        else
          logger.warn "#{controller_name}##{action_name}: StripeCheckoutSession is not found user_id=#{current_user.id}"
        end
      rescue => e
        logger.warn "#{controller_name}##{action_name}: #{e.inspect} stripe_checkout_session=#{@session&.inspect}"
      end

      def send_message
        if @session
          message = "user_id=#{current_user.id} checkout_session_id=#{@session.id} referer=#{request.referer.to_s.truncate(200)}"
          SendMessageToSlackWorker.perform_async(:orders_cs_created, "`#{Rails.env}` #{message}")
        else
          logger.warn "#{controller_name}##{action_name}: StripeCheckoutSession is not found user_id=#{current_user.id}"
        end
      rescue => e
        logger.warn "#{controller_name}##{action_name}: #{e.inspect} stripe_checkout_session=#{@session&.inspect}"
      end
    end
  end
end
