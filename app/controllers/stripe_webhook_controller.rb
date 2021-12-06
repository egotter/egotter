class StripeWebhookController < ApplicationController

  skip_before_action :verify_authenticity_token

  def index
    event = construct_event
    process_event(event)
    head :ok
  rescue => e
    Airbag.warn "#{controller_name}##{action_name} #{e.inspect} event_id=#{event.id}"
    head :bad_request
  end

  private

  def construct_event
    payload = request.body.read
    sig_header = request.headers['HTTP_STRIPE_SIGNATURE']
    Stripe::Webhook.construct_event(payload, sig_header, ENV['STRIPE_ENDPOINT_SECRET'])
  end

  def process_event(event)
    case event.type
    when 'checkout.session.completed'
      process_cs_completed(event)
    when 'charge.succeeded'
      process_charge_succeeded(event)
    when 'charge.failed'
      process_charge_failed(event)
    when 'payment_intent.succeeded'
      process_payment_intent_succeeded(event)
    else
      Airbag.info "Unhandled stripe webhook event type=#{event.type} value=#{event.inspect}"
    end
  end

  # As a user is waiting to finish the checkout, this process MUST be executed synchronously
  def process_cs_completed(event)
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
end
