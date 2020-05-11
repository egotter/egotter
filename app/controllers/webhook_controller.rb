require 'openssl'
require 'base64'

class WebhookController < ApplicationController
  include Concerns::PeriodicReportConcern

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

            if restart_requested?(dm)
              enqueue_user_requested_restarting_periodic_report(dm)
            end

            if send_now_requested?(dm) || continue_requested?(dm)
              enqueue_user_requested_periodic_report(dm)
            elsif stop_now_requested?(dm)
              enqueue_user_requested_stopping_periodic_report(dm)
            end

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
    dm.text.exclude?('#egotter') && dm.text != I18n.t('quick_replies.prompt_reports.label3') && dm.sender_id != User.egotter.uid
  end

  def sent_from_egotter?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id == User.egotter.uid
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
