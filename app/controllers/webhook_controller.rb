require 'openssl'
require 'base64'

class WebhookController < ApplicationController

  skip_before_action :verify_authenticity_token, only: :twitter

  before_action :verify_webhook_request, only: :twitter

  def challenge
    render json: {response_token: crc_response}
  end

  def twitter
    if direct_message_event_for_egotter?
      params[:direct_message_events].each do |event|
        event = event.to_unsafe_h if event.respond_to?(:to_unsafe_h)
        ProcessWebhookEventWorker.perform_async(event)
      end
    elsif follow_event_for_egotter?
      params[:follow_events].each do |event|
        event = event.to_unsafe_h if event.respond_to?(:to_unsafe_h)
        ProcessWebhookFollowEventWorker.perform_async(event)
      end
    elsif direct_message_event_for_egotter_cs?
      params[:direct_message_events].each do |event|
        event = event.to_unsafe_h if event.respond_to?(:to_unsafe_h)
        ProcessWebhookEventForEgotterCsWorker.perform_async(event)
      end
    else
      logger.info "#{controller_name}##{action_name}: Unhandled webhook event for_user_id=#{params[:for_user_id]}"
    end

    head :ok
  rescue => e
    logger.warn "#{controller_name}##{action_name}: #{e.inspect}"
    head :ok
  end

  private

  def direct_message_event_for_egotter?
    params[:for_user_id].to_i == User::EGOTTER_UID && params[:direct_message_events]
  end

  def follow_event_for_egotter?
    params[:for_user_id].to_i == User::EGOTTER_UID && params[:follow_events]
  end

  def direct_message_event_for_egotter_cs?
    params[:for_user_id].to_i == User::EGOTTER_CS_UID && params[:direct_message_events]
  end

  def crc_response
    crc_digest(params[:crc_token])
  end

  def verify_webhook_request
    unless crc_digest(request.body.read) == request.headers[:HTTP_X_TWITTER_WEBHOOKS_SIGNATURE]
      head :forbidden
    end
  end

  def crc_digest(payload)
    secret = ENV['TWITTER_CONSUMER_SECRET']
    digest = OpenSSL::HMAC::digest('sha256', secret, payload)
    "sha256=#{Base64.encode64(digest).strip!}"
  end
end
