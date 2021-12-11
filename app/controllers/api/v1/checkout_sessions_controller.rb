module Api
  module V1
    class CheckoutSessionsController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :doesnt_have_valid_subscription!

      after_action { track_page_order_activity(stripe_session_id: @stripe_session&.id) }
      after_action { send_message(@stripe_session&.id) }

      def create
        @stripe_session = create_session(current_user)
        render json: {session_id: @stripe_session.id}
      end

      private

      def create_session(user)
        attrs = CheckoutSessionBuilder.build(user)
        stripe_session = Stripe::Checkout::Session.create(attrs)
        CheckoutSession.create!(user_id: user.id, stripe_checkout_session_id: stripe_session.id, properties: {via: params[:via]})
        stripe_session
      end

      def send_message(session_id)
        message = tracking_params.merge(checkout_session_id: session_id)
        SlackMessage.create(channel: 'orders_cs_created', message: message)
        SendMessageToSlackWorker.perform_async(:orders_cs_created, "`#{Rails.env}` #{message}")
      end

      def tracking_params
        {
            user_id: current_user.id,
            via: params[:via],
            referer: request.referer.to_s.truncate(200),
        }
      end
    end
  end
end
