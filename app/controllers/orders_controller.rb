class OrdersController < ApplicationController

  skip_before_action :verify_authenticity_token, only: :checkout_session_completed

  before_action :require_login!, except: :checkout_session_completed
  before_action :has_already_purchased?, only: :create

  # TODO Remove later
  def create
    logger.warn "#{controller_name}##{action_name} is deprecated"

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

    redirect_to root_path(via: current_via), notice: t('.success_html', url: after_purchase_path('after_purchasing'))
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{current_user_id}"
    redirect_to root_path(via: current_via('error')), alert: t('.failed_html', url: after_purchase_path('after_purchasing_with_error')) unless performed?
  end

  # Not used: Callback URL for a successful payment
  def success
    checkout_session = Stripe::Checkout::Session.retrieve(params[:stripe_session_id])
    subscription_id = Order::CheckoutSession.new(checkout_session).subscription_id

    if Order.exists?(user_id: current_user.id, subscription_id: subscription_id)
      redirect_to root_path(via: current_via), notice: t('.success_html', url: after_purchase_path('after_purchasing'))
    else
      redirect_to root_path(via: current_via('order_not_found')), alert: t('.failed_html', url: after_purchase_path('after_purchasing_with_error'))
    end
  end

  # Callback URL for a canceled payment
  def cancel
    redirect_to root_path(via: current_via), notice: t('.canceled_html')
  end

  def checkout_session_completed
    event = construct_webhook_event
    process_webhook_event(event)
    head :ok
  rescue JSON::ParserError => e
    logger.warn "#{controller_name}##{action_name} Invalid payload exception=#{e.inspect}"
    head :bad_request
  rescue Stripe::SignatureVerificationError => e
    logger.warn "#{controller_name}##{action_name} Invalid signature exception=#{e.inspect}"
    head :bad_request
  rescue => e
    logger.warn "#{controller_name}##{action_name} Unknown error exception=#{e.inspect}"
    head :bad_request
  end

  private

  def construct_webhook_event
    payload = request.body.read
    sig_header = request.headers['HTTP_STRIPE_SIGNATURE']
    Stripe::Webhook.construct_event(payload, sig_header, ENV['STRIPE_ENDPOINT_SECRET'])
  end

  def process_webhook_event(event)
    case event.type
    when 'checkout.session.completed'
      process_checkout_session_completed(event.data)
    when 'charge.succeeded'
      process_charge_succeeded(event.data)
    when 'charge.failed'
      process_charge_failed(event.data)
    else
      logger.info "Unhandled stripe webhook event type=#{event.type} value=#{event.inspect}"
    end
  end

  def process_checkout_session_completed(event_data)
    order = nil
    checkout_session = Order::CheckoutSession.new(event_data['object'])
    user_id = checkout_session.client_reference_id
    user = User.find(user_id)

    if user.has_valid_subscription?
      Stripe::Subscription.delete(checkout_session.subscription_id)

      send_message("`#{Rails.env}:checkout_session_completed` already purchased user_id=#{user.id}")
    else
      set_tax_rate_to_subscription(checkout_session.subscription_id)
      order = Order.create_by!(checkout_session)
      set_metadata_to_subscription(checkout_session.subscription_id, order_id: order.id)

      SetVisitIdToOrderWorker.perform_async(order.id)
      UpdateTrialEndWorker.perform_async(order.id)

      send_message("`#{Rails.env}:checkout_session_completed` success user_id=#{user.id} order_id=#{order.id}")
    end
  rescue => e
    if order
      send_message("`#{Rails.env}:checkout_session_completed` order may be insufficient order=#{order.inspect} exception=#{e.inspect}")
    end
    raise
  end

  def process_charge_succeeded(event_data)
    customer_id = event_data['object']['customer']

    if (order = Order.find_by(customer_id: customer_id))
      order.charge_succeeded!
      send_message("`#{Rails.env}:charge_succeeded` success user_id=#{order.user_id} order_id=#{order.id}")
    else
      send_message("`#{Rails.env}:charge_succeeded` order not found customer_id=#{customer_id}")
    end
  rescue => e
    send_message("`#{Rails.env}:charge_succeeded` exception=#{e.inspect}")
    raise
  end

  def process_charge_failed(event_data)
    customer_id = event_data['object']['customer']

    if (order = Order.find_by(customer_id: customer_id))
      order.charge_failed!
      order.cancel!
      send_message("`#{Rails.env}:charge_failed` success user_id=#{order.user_id} order_id=#{order.id}")
    else
      send_message("`#{Rails.env}:charge_failed` order not found customer_id=#{customer_id}")
    end
  rescue => e
    send_message("`#{Rails.env}:charge_failed` exception=#{e.inspect}")
    raise
  end

  def set_tax_rate_to_subscription(subscription_id, tax_rate_id = ENV['STRIPE_TAX_RATE_ID'])
    Stripe::Subscription.update(subscription_id, {default_tax_rates: [tax_rate_id]})
  end

  def set_metadata_to_subscription(subscription_id, order_id:)
    Stripe::Subscription.update(subscription_id, {metadata: {order_id: order_id}})
  end

  def after_purchase_path(via)
    settings_path(anchor: 'orders-table', via: current_via(via))
  end

  def send_message(message)
    SendMessageToSlackWorker.perform_async(:orders, message)
  rescue => e
    logger.warn "#{controller_name}##{action_name}: #send_message is failed exception=#{e.inspect} caller=#{caller[0][/`([^']*)'/, 1] rescue ''} message=#{message}"
  end
end
