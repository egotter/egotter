class OrdersController < ApplicationController

  skip_before_action :current_user_not_blocker?, only: %i(success failure end_trial_failure)
  skip_before_action :verify_authenticity_token, only: :checkout_session_completed

  before_action :require_login!, except: :checkout_session_completed
  before_action :validate_stripe_session_id, only: :success

  after_action :track_order_activity

  def success
    checkout_session = Stripe::Checkout::Session.retrieve(params[:stripe_session_id])

    unless current_user.orders.where(subscription_id: checkout_session.subscription).exists?
      logger.warn "#{controller_name}##{action_name}: Order is not found user_id=#{current_user.id} checkout_session_id=#{checkout_session.id} subscription_id=#{checkout_session.subscription}"
      redirect_to orders_failure_path(via: current_via('order_not_found'))
    end
  rescue => e
    logger.warn "#{controller_name}##{action_name}: #{e.inspect} checkout_session_id=#{params[:stripe_session_id]}"
    redirect_to orders_failure_path(via: current_via('internal_error'))
  end

  def failure
    send_failure_message("user_id=#{current_user&.id} via=#{params[:via]}")
  end

  def end_trial_failure
    # TODO Fix the channel name
    send_failure_message("user_id=#{current_user&.id} via=#{params[:via]}")
  end

  def checkout_session_completed
    event = construct_webhook_event
    process_webhook_event(event)
    head :ok
  rescue => e
    logger.warn "#{controller_name}##{action_name} #{e.inspect}"
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
    when 'payment_intent.succeeded'
      process_payment_intent_succeeded(event.data)
    else
      logger.info "Unhandled stripe webhook event type=#{event.type} value=#{event.inspect}"
    end
  end

  def process_checkout_session_completed(event_data)
    order = nil
    checkout_session = event_data['object']
    user = User.find(checkout_session.client_reference_id)

    if user.has_valid_subscription?
      Stripe::Subscription.delete(checkout_session.subscription)

      send_cs_completed_message("User already have a subscription user_id=#{user.id}")
    else
      order = Order.create_by_webhook!(checkout_session)
      SyncOrderAndSubscriptionWorker.perform_async(order.id)

      # SetVisitIdToOrderWorker.perform_async(order.id)

      send_cs_completed_message("Success user_id=#{user.id} order_id=#{order.id}")
    end
  rescue => e
    send_cs_completed_message("Order may be insufficient order=#{order&.inspect} exception=#{e.inspect}")
    raise
  end

  def process_charge_succeeded(event_data)
    customer_id = event_data['object']['customer']

    if (order = Order.order(created_at: :desc).find_by(customer_id: customer_id))
      order.charge_succeeded!
      send_charge_succeeded_message("Success user_id=#{order.user_id} order_id=#{order.id}")
    else
      send_charge_succeeded_message("Order not found customer_id=#{customer_id}")
    end
  rescue => e
    send_charge_succeeded_message("exception=#{e.inspect}")
    raise
  end

  def process_charge_failed(event_data)
    customer_id = event_data['object']['customer']

    if (order = Order.order(created_at: :desc).find_by(customer_id: customer_id))
      order.charge_failed!
      order.cancel!('webhook')
      send_charge_failed_message("Success user_id=#{order.user_id} order_id=#{order.id} customer_id=#{customer_id}")
    else
      send_charge_failed_message("Order not found customer_id=#{customer_id}")
    end
  rescue => e
    send_charge_failed_message("#{e.inspect} event=#{event_data.inspect}")
    raise
  end

  def process_payment_intent_succeeded(event_data)
    order = nil
    stripe_payment_intent = event_data['object']

    return unless StripePaymentIntent.intent_for_bank_transfer?(stripe_payment_intent)

    unless (payment_intent = PaymentIntent.find_by(stripe_payment_intent_id: stripe_payment_intent.id))
      send_pi_succeeded_message("PaymentIntent not found stripe_payment_intent_id=#{stripe_payment_intent.id}")
      return
    end

    user = payment_intent.user
    stripe_customer = Stripe::Customer.retrieve(stripe_payment_intent.customer)

    if user.has_valid_subscription?
      send_pi_succeeded_message("User already have a subscription user_id=#{user.id}")
    else
      order = Order.create_by_bank_transfer(user, stripe_customer)
      payment_intent.update(succeeded_at: Time.zone.now)
      send_pi_succeeded_message("Success user_id=#{user.id} order_id=#{order.id}")
    end
  rescue => e
    send_pi_succeeded_message("Order may be insufficient order=#{order&.inspect} exception=#{e.inspect}")
    raise
  end

  def send_failure_message(message)
    SendMessageToSlackWorker.perform_async(:orders_failure, "`#{Rails.env}:failure` #{message}")
  rescue => e
    logger.warn "#send_failure_message failed exception=#{e.inspect} message=#{message}"
  end

  def send_cs_completed_message(message)
    SendMessageToSlackWorker.perform_async(:orders_cs_completed, "`#{Rails.env}:checkout_session_completed` #{message}")
  rescue => e
    logger.warn "#send_cs_completed_message failed exception=#{e.inspect} message=#{message}"
  end

  def send_charge_succeeded_message(message)
    SendMessageToSlackWorker.perform_async(:orders_charge_succeeded, "`#{Rails.env}:charge_succeeded` #{message}")
  rescue => e
    logger.warn "#send_charge_succeeded_message failed exception=#{e.inspect} message=#{message}"
  end

  def send_charge_failed_message(message)
    SendMessageToSlackWorker.perform_async(:orders_charge_failed, "`#{Rails.env}:charge_failed` #{message}")
  rescue => e
    logger.warn "#send_charge_failed_message failed exception=#{e.inspect} message=#{message}"
  end

  def send_pi_succeeded_message(message)
    SendMessageToSlackWorker.perform_async(:orders_pi_succeeded, "`#{Rails.env}:payment_intent_succeeded` #{message}")
  rescue => e
    logger.warn "#send_pi_succeeded_message failed exception=#{e.inspect} message=#{message}"
  end

  def validate_stripe_session_id
    if params[:stripe_session_id].blank?
      redirect_to settings_path(anchor: 'orders-table', via: current_via('stripe_session_id_not_found'))
    end
  end
end
