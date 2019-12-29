require 'openssl'
require 'base64'

class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :twitter

  def challenge
    render json: {response_token: crc_response}
  end

  def twitter
    if verified_request? && params[:for_user_id].to_i == User.egotter.uid && params[:direct_message_events]
      params[:direct_message_events].each do |event|
        if event['type'] == 'message_create'
          dm = DirectMessage.new(event: event.to_unsafe_h.deep_symbolize_keys)
          found = dm.text.exclude?('#egotter') && dm.sender_id != User.egotter.uid
          logger.info "#{controller_name}##{action_name} #{found} #{dm.id} #{dm.text}"

          CreateAnswerMessageWorker.perform_async(dm.sender_id, text: "#{dm.id} #{dm.text}") if found
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

  def verified_request?
    digest(request.body.read) == request.headers[:HTTP_X_TWITTER_WEBHOOKS_SIGNATURE]
  end

  def digest(payload)
    secret = ENV['TWITTER_CONSUMER_SECRET']
    digest = OpenSSL::HMAC::digest('sha256', secret, payload)
    "sha256=#{Base64.encode64(digest).strip!}"
  end
end
