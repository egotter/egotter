require 'openssl'
require 'base64'

class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def challenge
    render json: {response_token: "sha256=#{crc_response}"}
  end

  def twitter
    head :ok
  end

  def crc_response
    token = params[:crc_token]
    secret = ENV['TWITTER_CONSUMER_SECRET']
    digest = OpenSSL::HMAC::hexdigest('sha256', secret, token)
    Base64.encode64(digest).strip!
  end
end
