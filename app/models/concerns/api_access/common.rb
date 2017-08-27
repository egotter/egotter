require 'active_support/concern'

module Concerns::ApiAccess::Common
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def api_client
    ApiClient.instance(access_token: token, access_token_secret: secret)
  end

  def rate_limit
    api_client.rate_limit
  end
end