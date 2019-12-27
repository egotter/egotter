class OrdersController < ApplicationController

  skip_before_action :verify_authenticity_token, only: :checkout_session_completed

  before_action :require_login!, except: :checkout_session_completed
  before_action :has_already_purchased?, only: :create
  before_action :create_search_log

  after_action only: %i(create destroy checkout_session_completed) do
    order =
        if action_name == 'create'
          current_user.orders.last
        elsif action_name == 'destroy'
          current_user.orders.find_by(id: params[:id])
        elsif action_name == 'checkout_session_completed'
          Order.where(created_at: 3.seconds.ago..Time.zone.now).last
        else
          raise
        end
    send_message_to_slack("#{order.inspect}", title: "`#{Rails.env}:#{action_name}`") if order
  rescue => e
    logger.warn "#{self.class} Sending a message to slack is failed #{e.inspect}"
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
        items: [{plan: Order::BASIC_PLAN_ID}],
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
    notify_airbrake(e)
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
    notify_airbrake(e)
    redirect_to root_path, alert: t('.failed_html', url: after_purchase_path('after_canceling_with_error')) unless performed?
  end

  def success
    checkout_session = Stripe::Checkout::Session.retrieve(params[:stripe_session_id])
    subscription_id = Order::CheckoutSession.new(checkout_session).subscription_id

    if Order.exists?(user_id: current_user.id, subscription_id: subscription_id)
      redirect_to root_path(via: build_via('order_found')), notice: t('.success_html', url: after_purchase_path('after_purchasing'))
    else
      redirect_to root_path(via: build_via('order_not_found')), alert: t('.failed_html', url: after_purchase_path('after_purchasing_with_error'))
    end
  end

  def cancel
    redirect_to root_path(via: build_via), notice: t('.canceled_html')
  end

  def checkout_session_completed
    payload = request.body.read
    sig_header = request.headers['HTTP_STRIPE_SIGNATURE']

    event = Stripe::Webhook.construct_event(
        payload,
        sig_header,
        ENV['STRIPE_ENDPOINT_SECRET']
    )

    if event['type'] == 'checkout.session.completed'
      checkout_session = Order::CheckoutSession.new(event['data']['object'])
      if User.find(checkout_session.client_reference_id).has_valid_subscription?
        Stripe::Subscription.delete(checkout_session.subscription_id)
      else
        Stripe::Subscription.update(
            checkout_session.subscription_id,
            {default_tax_rates: [ENV['STRIPE_TAX_RATE_ID']]}
        )

        order = Order.create_by!(checkout_session: checkout_session)

        Stripe::Subscription.update(
            checkout_session.subscription_id,
            {metadata: {order_id: order.id}}
        )
      end
    end

    head :ok

  rescue JSON::ParserError => e
    logger.warn "#{controller_name}##{action_name} Invalid payload #{payload.inspect}"
    head :bad_request
  rescue Stripe::SignatureVerificationError => e
    logger.warn "#{controller_name}##{action_name} Invalid signature #{sig_header.inspect}"
    head :bad_request
  rescue => e
    logger.warn "#{controller_name}##{action_name} #{e.class} #{e.message}"
    head :bad_request
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
