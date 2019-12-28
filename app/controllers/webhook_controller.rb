require 'openssl'
require 'base64'

class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def challenge
    render json: {response_token: "sha256=#{crc_response}"}
  end

  def twitter
    begin
      logger.info "#{controller_name}##{action_name} #{params.inspect}"
      logger.info "#{controller_name}##{action_name} #{request.query_parameters.inspect}"
      logger.info "#{controller_name}##{action_name} #{params[:for_user_id]}"
      if params[:direct_message_events]
        JSON.parse(params[:direct_message_events]).each do |event|
          logger.info "#{controller_name}##{action_name} #{event}"
        end
      end
    rescue => e
      logger.warn "#{controller_name}##{action_name} #{e.inspect}"
    end

    head :ok
  end

  def crc_response
    token = params[:crc_token]
    secret = ENV['TWITTER_CONSUMER_SECRET']
    digest = OpenSSL::HMAC::digest('sha256', secret, token)
    Base64.encode64(digest).strip!
  end
end
