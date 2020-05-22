require 'openssl'
require 'base64'

class WebhookController < ApplicationController
  include Concerns::PeriodicReportConcern

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

  def process_direct_message_event(event)
    return unless event['type'] == 'message_create'

    dm = DirectMessage.new(event: event.deep_symbolize_keys)

    if sent_from_user?(dm)
      process_message_from_user(dm)
    elsif sent_from_egotter?(dm)
      process_message_from_egotter(dm)
    end

    if message_from_user?(dm)
      GlobalTotalDirectMessageReceivedFlag.new.received(dm.sender_id)
    elsif message_from_egotter?(dm)
      GlobalTotalDirectMessageSentFlag.new.received(dm.recipient_id)
    end
  end

  def process_message_from_user(dm)
    GlobalDirectMessageReceivedFlag.new.received(dm.sender_id)
    GlobalSendDirectMessageCountByUser.new.clear(dm.sender_id)

    if restart_requested?(dm)
      enqueue_user_requested_restarting_periodic_report(dm)
      enqueue_user_requested_periodic_report(dm, fuzzy: true)
    elsif send_now_requested?(dm)
      enqueue_user_requested_periodic_report(dm)
    elsif continue_requested?(dm)
      enqueue_user_requested_periodic_report(dm, fuzzy: true)
    elsif stop_now_requested?(dm)
      enqueue_user_requested_stopping_periodic_report(dm)
    elsif report_received?(dm)
      enqueue_user_received_periodic_report(dm)
    else
      logger.info { "#{__method__} dm is ignored #{dm.text}" }
    end

    SendReceivedMessageWorker.perform_async(dm.sender_id, dm_id: dm.id, text: dm.text)
  end

  def process_message_from_egotter(dm)
    GlobalDirectMessageSentFlag.new.received(dm.recipient_id)

    if send_now_requested?(dm)
      enqueue_egotter_requested_periodic_report(dm)
    end

    SendSentMessageWorker.perform_async(dm.recipient_id, dm_id: dm.id, text: dm.text)
  end

  # TODO Rename to message_from_user_by_hand?
  def sent_from_user?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id != User::EGOTTER_UID
  end

  # TODO Rename to message_from_egotter_by_hand?
  def sent_from_egotter?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id == User::EGOTTER_UID
  end

  def message_from_user?(dm)
    dm.sender_id != User::EGOTTER_UID
  end

  def message_from_egotter?(dm)
    dm.sender_id == User::EGOTTER_UID
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
