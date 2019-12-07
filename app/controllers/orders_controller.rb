class OrdersController < ApplicationController

  before_action :require_login!
  before_action :has_already_purchased?
  before_action :create_search_log

  def create
    order = current_user.orders.create!(email: params[:stripeEmail])

    customer = Stripe::Customer.create(
        email: params[:stripeEmail],
        source: params[:stripeToken],
        metadata: {order_id: order.id}
    )

    order.update!(customer_id: customer.id)

    subscription = Stripe::Subscription.create(
        customer: customer.id,
        items: [{plan: ENV['STRIPE_BASIC_PLAN_ID']}],
        metadata: {order_id: order.id}
    )

    order.update!(subscription_id: subscription.id)
    order.update!(name: subscription.items.data[0].plan.nickname, price: subscription.items.data[0].plan.amount)

    order.update!(
        search_count: SearchCountLimitation::BASIC_PLAN,
        follow_requests_count: Rails.configuration.x.constants['basic_plan_follow_requests_limit'],
        unfollow_requests_count: Rails.configuration.x.constants['basic_plan_unfollow_requests_limit'],
    )

    flash[:notice] = t('orders.create.success_html', url: settings_path)
    redirect_to root_path

  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{current_user_id}"
    redirect_to root_path, alert: t('orders.create.failed_html', url: settings_path) unless performed?
  end
end
