module Api
  module V1
    class CheckoutSessionsController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :doesnt_have_valid_subscription!

      after_action { track_order_activity(checkout_session: {id: @session&.id, customer: @session&.customer, metadata: @session&.metadata}) }

      def create
        attrs = build_checkout_session_attrs(current_user)
        @session = Stripe::Checkout::Session.create(attrs)
        render json: {session_id: @session.id}
      end

      private

      def build_checkout_session_attrs(user)
        attrs = {
            client_reference_id: user.id,
            payment_method_types: ['card'],
            mode: 'subscription',
            line_items: [{quantity: 1, price: Order::BASIC_PLAN_PRICE_ID}],
            subscription_data: {default_tax_rates: [Order::TAX_RATE_ID]},
            metadata: {user_id: user.id},
            success_url: ENV['STRIPE_SUCCESS_URL'],
            cancel_url: ENV['STRIPE_CANCEL_URL'],
        }

        if (customer_id = user.valid_customer_id)
          attrs[:customer] = customer_id
          attrs[:discounts] = []
          attrs[:metadata][:price] = Order::REGULAR_PRICE
        else
          attrs[:subscription_data][:trial_period_days] = Order::TRIAL_DAYS
          attrs[:discounts] = [{coupon: Order::COUPON_ID}]
          attrs[:metadata][:price] = Order::DISCOUNT_PRICE
        end

        if attrs[:discounts].empty? && user.coupons_stripe_coupon_ids.any?
          attrs[:discounts] = [{coupon: user.coupons_stripe_coupon_ids[-1]}]
          attrs[:metadata][:price] = Order::DISCOUNT_PRICE
        end

        attrs
      end
    end
  end
end
