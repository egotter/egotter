class Stripe::WebhooksController < ApplicationController

  skip_before_action :verify_authenticity_token

  ENDPOINT_SECRET = ENV['STRIPE_ENDPOINT_SECRET']

  def webhook
    payload = request.body.read
    sig_header = request.headers[:HTTP_STRIPE_SIGNATURE]
    event = Stripe::Webhook.construct_event(payload, sig_header, ENDPOINT_SECRET)

    StripeDB::Event.create!(event_id: event.id, event_type: event.type, idempotency_key: event.request.idempotency_key)

    # TODO Set plan_id to nil when the plan is canceled or the charge is failed.

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    logger.warn "#{controller_name}##{action_name}: #{e.class} #{e.message} #{params.inspect} #{request.body.read.inspect}"
    head :bad_request
  rescue => e
    logger.warn "#{controller_name}##{action_name}: #{e.class} #{e.message} #{params.inspect} #{request.body.read.inspect}"
    head :internal_server_error
  end
end
