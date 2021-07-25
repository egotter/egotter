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
    send_failure_message("user_id=#{current_user&.id} referer=#{request.referer.to_s.truncate(200)}")
  end

  def end_trial_failure
    send_end_trial_failure_message("user_id=#{current_user&.id} referer=#{request.referer.to_s.truncate(200)}")
  end

  def checkout_session_completed
    event = construct_webhook_event
    process_webhook_event(event)
    head :ok
  rescue => e
    logger.warn "#{controller_name}##{action_name} #{e.inspect} event_id=#{event.data}"
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
      process_checkout_session_completed(event)
    when 'charge.succeeded'
      process_charge_succeeded(event)
    when 'charge.failed'
      process_charge_failed(event)
    when 'payment_intent.succeeded'
      process_payment_intent_succeeded(event)
    else
      logger.info "Unhandled stripe webhook event type=#{event.type} value=#{event.inspect}"
    end
  end

  def process_checkout_session_completed(event)
    checkout_session_id = event.data.object.id
    ProcessStripeCheckoutSessionCompletedEventWorker.perform_async(checkout_session_id)
  end

  def process_charge_succeeded(event)
    customer_id = event.data.object.customer
    ProcessStripeChargeSucceededEventWorker.perform_async(customer_id)
  end

  def process_charge_failed(event)
    customer_id = event.data.object.customer
    ProcessStripeChargeFailedEventWorker.perform_async(customer_id)
  end

  def process_payment_intent_succeeded(event)
    stripe_payment_intent_id = event.data.object.id
    ProcessStripePaymentIntentSucceededEventWorker.perform_async(stripe_payment_intent_id)
  end

  def send_failure_message(message)
    SendMessageToSlackWorker.perform_async(:orders_failure, "`#{Rails.env}` #{message}")
  rescue => e
    logger.warn "##{__method__} failed exception=#{e.inspect} message=#{message}"
  end

  def send_end_trial_failure_message(message)
    SendMessageToSlackWorker.perform_async(:orders_end_trial_failure, "`#{Rails.env}` #{message}")
  rescue => e
    logger.warn "##{__method__} failed exception=#{e.inspect} message=#{message}"
  end

  def validate_stripe_session_id
    if params[:stripe_session_id].blank?
      redirect_to settings_path(anchor: 'orders-table', via: current_via('stripe_session_id_not_found'))
    end
  end
end
