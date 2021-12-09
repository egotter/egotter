module Api
  module V1
    class CheckoutSessionsController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :doesnt_have_valid_subscription!

      after_action { send_message(@checkout_session.id) }

      def create
        @checkout_session = create_checkout_session(current_user)
        render json: {session_id: @checkout_session.stripe_checkout_session_id}
      end

      private

      def create_checkout_session(user)
        if params.has_key?(:item_id) && Order::BASIC_PLAN_MONTHLY_BASIS.has_key?(params[:item_id])
          attrs = CheckoutSessionBuilder.monthly_basis(user, params[:item_id])
        else
          attrs = CheckoutSessionBuilder.monthly_subscription(user)
        end
        stripe_session = Stripe::Checkout::Session.create(attrs)
        CheckoutSession.create!(user_id: user.id, stripe_checkout_session_id: stripe_session.id, properties: {item_id: params[:item_id], via: params[:via]})
      end

      def send_message(session_id)
        message_params = {
            user_id: current_user.id,
            checkout_session_id: session_id,
            via: params[:via],
            referer: request.referer.to_s.truncate(200),
        }
        SlackMessage.create(channel: 'orders_cs_created', message: message_params)
        SendMessageToSlackWorker.perform_async(:orders_cs_created, "`#{Rails.env}` #{message_params}")
      rescue => e
        Airbag.warn "#{controller_name}##{__method__}: #{e.inspect} checkout_session_id=#{session_id}"
      end
    end
  end
end
