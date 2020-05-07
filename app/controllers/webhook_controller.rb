require 'openssl'
require 'base64'

class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :twitter

  def challenge
    render json: {response_token: crc_response}
  end

  def twitter
    if verified_webhook_request? && params[:for_user_id].to_i == User.egotter.uid && params[:direct_message_events]
      params[:direct_message_events].each do |event|
        if event['type'] == 'message_create'
          dm = DirectMessage.new(event: event.to_unsafe_h.deep_symbolize_keys)

          if sent_from_user?(dm)
            GlobalDirectMessageReceivedFlag.new.received(dm.sender_id)
            enqueue_user_requested_periodic_report(dm)
            SendReceivedMessageWorker.perform_async(dm.sender_id, dm_id: dm.id, text: dm.text)
          elsif sent_from_egotter?(dm)
            enqueue_egotter_requested_periodic_report(dm)
            SendSentMessageWorker.perform_async(dm.recipient_id, dm_id: dm.id, text: dm.text)
          end
        end
      end
    end

    head :ok
  rescue => e
    logger.warn "#{controller_name}##{action_name} #{e.inspect}"
    notify_airbrake(e)
    head :ok
  end

  private

  def sent_from_user?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id != User.egotter.uid
  end

  def sent_from_egotter?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id == User.egotter.uid
  end

  # t('quick_replies.prompt_reports.label3')
  SEND_NOW_REGEXP = /今すぐ送信|いますぐ送信|今すぐそうしん|いますぐそうしん/

  def enqueue_user_requested_periodic_report(dm)
    if dm.text.match?(SEND_NOW_REGEXP)
      user = User.find_by(uid: dm.sender_id)
      if user
        if user.authorized?
          request = CreatePeriodicReportRequest.create(user_id: user.id)
          CreateUserRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id, create_twitter_user: true)
        else
          CreatePeriodicReportMessageWorker.perform_async(user.id, unauthorized: true)
        end
      else
        CreatePeriodicReportMessageWorker.perform_async(nil, unregistered: true, uid: dm.sender_id)
      end
    end
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def enqueue_egotter_requested_periodic_report(dm)
    if dm.text.match?(SEND_NOW_REGEXP)
      user = User.find_by(uid: dm.recipient_id)
      if user
        if user.authorized?
          request = CreatePeriodicReportRequest.create(user_id: user.id)
          CreateEgotterRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id, create_twitter_user: true)
        else
          CreatePeriodicReportMessageWorker.perform_async(user.id, unauthorized: true)
        end
      else
        CreatePeriodicReportMessageWorker.perform_async(nil, unregistered: true, uid: dm.recipient_id)
      end
    end
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
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
