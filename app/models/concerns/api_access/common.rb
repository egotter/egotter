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
    RateLimit.new(api_client.send(:perform_get, '/1.1/application/rate_limit_status.json')) rescue nil
  end

  class RateLimit
    def initialize(status)
      @status = status
    end

    def resources
      @status[:resources]
    end

    def verify_credentials
      {
        remaining: resources[:account][:'/account/verify_credentials'][:remaining],
        reset_in: (Time.zone.at(resources[:account][:'/account/verify_credentials'][:reset]) - Time.zone.now).round
      }
    end

    def friend_ids
      {
        remaining: resources[:friends][:'/friends/ids'][:remaining],
        reset_in: (Time.zone.at(resources[:friends][:'/friends/ids'][:reset]) - Time.zone.now).round
      }
    end

    def follower_ids
      {
        remaining: resources[:followers][:'/followers/ids'][:remaining],
        reset_in: (Time.zone.at(resources[:followers][:'/followers/ids'][:reset]) - Time.zone.now).round
      }
    end

    def inspect
      'verify_credentials ' + verify_credentials.inspect + ' friend_ids ' + friend_ids.inspect + ' follower_ids ' + follower_ids.inspect
    end
  end
end