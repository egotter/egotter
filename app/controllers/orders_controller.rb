class OrdersController < ApplicationController

  before_action :require_login!
  before_action :has_already_purchased?
  before_action :create_search_log

  def create
    order = Order.create!(user_id: current_user.id)

    customer = Stripe::Customer.create(
        email: params[:stripeEmail],
        source: params[:stripeToken],
        metadata: {order_id: order.id}
    )

    subscription = Stripe::Subscription.create(
        customer: customer.id,
        items: [{plan: ENV['STRIPE_BASIC_PLAN_ID']}],
        metadata: {order_id: order.id}
    )

    order.update!(
        search_count: Rails.configuration.x.constants['basic_plan_search_histories_limit'],
        customer_id: customer.id,
        subscription_id: subscription.id
    )

    flash[:notice] = t('orders.create.success_html', url: settings_path)
    redirect_to root_path
  end
end
