module Api
  module V1
    class CheckoutSessionsController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :doesnt_have_valid_subscription!

      after_action { track_page_order_activity(stripe_session_id: @stripe_session_id, button_id: params[:button_id]) }
      after_action { send_message(@stripe_session_id) }

      def create
        render json: {session_id: create_session(current_user)}
      end

      private

      def create_session(user)
        stripe_session = StripeCheckoutSession.create(user)
        CheckoutSession.create!(user_id: user.id, stripe_checkout_session_id: stripe_session.id, properties: {button_id: params[:button_id]})
        @stripe_session_id = stripe_session.id
      end

      # TODO Remove later
      def send_message(session_id)
        message = tracking_message(session_id)
        SlackMessage.create(channel: 'orders_cs_created', message: message)
        SendMessageToSlackWorker.perform_async(:orders_cs_created, "`#{Rails.env}` #{message}")
      end

      def tracking_message(session_id)
        tracking_params.merge(checkout_session_id: session_id).map { |k, v| "#{k}=#{v}" }.join(' ')
      end

      def tracking_params
        {
            user_id: current_user.id,
            button_id: params[:button_id],
            via: params[:via],
            referer: request.referer.to_s.truncate(200),
        }
      end
    end
  end
end
