require 'openssl'
require 'base64'

class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def challenge
    render json: {response_token: "sha256=#{crc_response(params[:crc_token])}"}
  end

  def twitter
    head :ok
  end

  def crc_response(token)
    secret = ENV['TWITTER_CONSUMER_SECRET']
    Base64.encode64(OpenSSL::HMAC::hexdigest('sha256', secret, token))
  end
end
