module Api
  module V1
    class CheckoutSessionsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!
      before_action :doesnt_have_valid_subscription!
      after_action { track_order_activity(checkout_session: {id: @session&.id, customer: @session&.customer, metadata: @session&.metadata}) }

      def create
        attrs = {
            client_reference_id: current_user.id,
            payment_method_types: ['card'],
            mode: 'subscription',
            line_items: [{quantity: 1, price: Order::BASIC_PLAN_PRICE_ID}],
            subscription_data: {default_tax_rates: [Order::TAX_RATE_ID]},
            metadata: {user_id: current_user.id},
            success_url: ENV['STRIPE_SUCCESS_URL'],
            cancel_url: pricing_url(via: 'cancel_checkout'),
        }

        if (order = current_user.orders.where.not(customer_id: :nil).order(created_at: :desc).first)
          attrs[:customer] = order.customer_id
          attrs[:metadata][:price] = Order::REGULAR_PRICE
        else
          attrs[:subscription_data][:trial_period_days] = Order::TRIAL_DAYS
          attrs[:discounts] = [{coupon: Order::COUPON_ID}]
          attrs[:metadata][:price] = Order::DISCOUNT_PRICE
        end

        @session = Stripe::Checkout::Session.create(attrs)

        render json: {session_id: @session.id}
      end
    end
  end
end
