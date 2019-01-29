require 'active_support/concern'

module Concerns::User::ApiAccess
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def api_client(options = {})
    ::ApiClient.instance({access_token: token, access_token_secret: secret}.merge(options))
  end

  def rate_limit
    api_client.rate_limit
  end
end