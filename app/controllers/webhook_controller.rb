require 'openssl'
require 'base64'

class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def challenge
    render json: {response_token: "sha256=#{crc_response}"}
  end

  def twitter
    logger.info "headers #{request.headers.sort.inspect}" rescue
    logger.info "generated digest #{digest(request.body.read)}" rescue
    logger.info "passed signature #{request.headers[:X_TWITTER_WEBHOOKS_SIGNATURE]}" rescue
    logger.info "match? #{digest(request.body.read) == request.headers[:X_TWITTER_WEBHOOKS_SIGNATURE]}" rescue

    if params[:for_user_id].to_i == User.egotter.uid && params[:direct_message_events]
      params[:direct_message_events].each do |event|
        if event['type'] == 'message_create'
          dm = DirectMessage.new(event: event.to_unsafe_h.deep_symbolize_keys)
          logger.info "event #{event.to_unsafe_h.deep_symbolize_keys.inspect}"
          logger.info "direct message #{dm.inspect}"
          logger.info "direct message #{dm.id}"
          logger.info "direct message #{dm.text}"

          found = dm.text.exclude?('#egotter') && dm.sender_id != User.egotter.uid
          logger.info "#{controller_name}##{action_name} #{found} #{dm.id} #{dm.text}"
          CreateAnswerMessageWorker.perform_async(dm.sender_id, text: "#{found} #{dm.id} #{dm.text}")
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

  def crc_response
    digest(params[:crc_token])
  end

  def digest(payload)
    secret = ENV['TWITTER_CONSUMER_SECRET']
    digest = OpenSSL::HMAC::digest('sha256', secret, payload)
    Base64.encode64(digest).strip!
  end
end
