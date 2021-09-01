class OrdersController < ApplicationController

  skip_before_action :current_user_not_blocker?, only: %i(success failure end_trial_failure)
  skip_before_action :verify_authenticity_token, only: :checkout_session_completed

  before_action :require_login!, only: %i(success failure end_trial_failure)
  before_action :set_stripe_checkout_session, only: :success

  after_action :track_order_activity

  def success
    unless current_user.orders.where(subscription_id: @checkout_session.subscription).exists?
      redirect_to orders_failure_path(via: 'order_not_found', stripe_session_id: params[:stripe_session_id])
    end
  rescue => e
    logger.warn "#{controller_name}##{action_name}: #{e.inspect} checkout_session_id=#{params[:stripe_session_id]}"
    redirect_to orders_failure_path(via: 'internal_error', stripe_session_id: params[:stripe_session_id])
  end

  # Redirecting to this action only takes place within OrdersController.
  def failure
    send_message(:orders_failure, stripe_session_id: params[:stripe_session_id])
  end

  def end_trial_failure
    send_message(:orders_end_trial_failure)
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

  # As a user is waiting to finish the checkout, this process MUST be executed synchronously
  def process_checkout_session_completed(event)
    checkout_session_id = event.data.object.id
    ProcessStripeCheckoutSessionCompletedEventWorker.new.perform(checkout_session_id)
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

  def send_message(channel, options = {})
    options.merge!(
        user_id: current_user&.id,
        via: params[:via],
        referer: request.referer.to_s.truncate(200)
    )
    message = options.map { |k, v| "#{k}=#{v}" }.join(' ')

    SlackMessage.create(channel: channel, message: message)
    SendMessageToSlackWorker.perform_async(channel, "`#{Rails.env}` #{message}")
  rescue => e
    logger.warn "#{action_name}##{__method__}: #{e.inspect} channel=#{channel} options=#{options.inspect}"
  end

  def set_stripe_checkout_session
    if params[:stripe_session_id]
      @checkout_session = Stripe::Checkout::Session.retrieve(params[:stripe_session_id])
    else
      redirect_to settings_order_history_path(via: current_via('stripe_session_id_not_found'))
    end
  end
end
