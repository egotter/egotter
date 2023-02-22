module Api
  module V1
    class CheckoutSessionsController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :doesnt_have_valid_subscription!

      after_action { track_page_order_activity(stripe_session_id: @stripe_session.id) }
      after_action { send_message(@stripe_session) }

      def create
        @stripe_session = create_session(current_user)
        render json: {session_id: @stripe_session.id}
      end

      private

      def create_session(user)
        if params.has_key?(:item_id) && Order::BASIC_PLAN_MONTHLY_BASIS.has_key?(params[:item_id])
          attrs = CheckoutSessionBuilder.monthly_basis(user, params[:item_id])
        else
          attrs = CheckoutSessionBuilder.monthly_subscription(user)
        end

        CheckoutSession.expire_all(user.id)

        stripe_session = Stripe::Checkout::Session.create(attrs)
        CheckoutSession.create!(user_id: user.id, stripe_checkout_session_id: stripe_session.id, properties: {via: params[:via], item_id: params[:item_id]}.compact)

        stripe_session
      end

      def send_message(stripe_session)
        message = {user_id: current_user.id, via: params[:via], checkout_session_id: stripe_session.id, mode: stripe_session.mode}
        SendMessageToSlackWorker.perform_async(:orders_cs_created, "`#{Rails.env}` #{message}")
      end
    end
  end
end
