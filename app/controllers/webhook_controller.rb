require 'openssl'
require 'base64'

class WebhookController < ApplicationController

  skip_before_action :verify_authenticity_token, only: :twitter

  def challenge
    render json: {response_token: crc_response}
  end

  def twitter
    if verified_webhook_request? && direct_message_event_for_egotter?
      params[:direct_message_events].each do |event|
        event = event.to_unsafe_h if event.respond_to?(:to_unsafe_h)
        ProcessWebhookEventWorker.perform_async(event)
      end
    end

    head :ok
  rescue => e
    logger.warn "#{controller_name}##{action_name} #{e.inspect}"
    notify_airbrake(e)
    head :ok
  end

  private

  def direct_message_event_for_egotter?
    params[:for_user_id].to_i == User::EGOTTER_UID && params[:direct_message_events]
  end

  def crc_response
    crc_digest(params[:crc_token])
  end

  # NOTICE The name #verified_request? conflicts with an existing method in Rails.
  def verified_webhook_request?
    crc_digest(request.body.read) == request.headers[:HTTP_X_TWITTER_WEBHOOKS_SIGNATURE]
  end

  def crc_digest(payload)
    secret = ENV['TWITTER_CONSUMER_SECRET']
    digest = OpenSSL::HMAC::digest('sha256', secret, payload)
    "sha256=#{Base64.encode64(digest).strip!}"
  end
end
