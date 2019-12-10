class OrdersController < ApplicationController

  before_action :require_login!
  before_action :has_already_purchased?, only: :create
  before_action :create_search_log

  after_action do
    order =
        if action_name == 'create'
          current_user.orders.last
        elsif action_name == 'destroy'
          current_user.orders.find_by(id: params[:id])
        else
          raise
        end

    send_message_to_slack("#{order.inspect}", title: "`#{action_name}`")
  end

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

    order.update!(
        subscription_id: subscription.id,
        name: subscription.items.data[0].plan.nickname,
        price: subscription.items.data[0].plan.amount,
        search_count: SearchCountLimitation::BASIC_PLAN,
        follow_requests_count: CreateFollowLimitation::BASIC_PLAN,
        unfollow_requests_count: CreateUnfollowLimitation::BASIC_PLAN,
    )

    redirect_to root_path, notice: t('.success_html', url: after_purchase_path('after_purchasing'))
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{current_user_id}"
    logger.info e.backtrace.join("\n")
    redirect_to root_path, alert: t('.failed_html', url: after_purchase_path('after_purchasing_with_error')) unless performed?
  end

  def destroy
    order = current_user.orders.find_by(id: params[:id])

    if order.canceled_at
      redirect_to root_path, notice: t('.already_canceled_html', url: after_purchase_path('after_canceling'))
    else
      order.cancel!
      redirect_to root_path, notice: t('.success_html', url: after_purchase_path('after_canceling'))
    end

  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{current_user_id}"
    logger.info e.backtrace.join("\n")
    redirect_to root_path, alert: t('.failed_html', url: after_purchase_path('after_canceling_with_error')) unless performed?
  end

  private

  def after_purchase_path(via)
    settings_path(anchor: 'orders-table', via: build_via(via))
  end

  def send_message_to_slack(text, title:)
    SlackClient.orders.send_message(text, title: title)
  rescue => e
    logger.warn "#{self.class}##{action_name} Sending a message to slack is failed #{e.inspect}"
  end
end
