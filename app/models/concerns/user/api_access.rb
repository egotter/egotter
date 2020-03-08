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
    path = '/1.1/application/rate_limit_status.json'
    request = Twitter::REST::Request.new(api_client.twitter, :get, path, {})
    RateLimit.new(request.perform)
  end

  class RateLimit
    def initialize(status)
      @status = status
    end

    def resources
      @status[:resources]
    end

    def verify_credentials
      extract_remaining_and_reset_in(resources[:account][:'/account/verify_credentials'])
    end

    def friend_ids
      extract_remaining_and_reset_in(resources[:friends][:'/friends/ids'])
    end

    def follower_ids
      extract_remaining_and_reset_in(resources[:followers][:'/followers/ids'])
    end

    def users
      extract_remaining_and_reset_in(resources[:users][:'/users/lookup'])
    end

    def to_h
      {
          verify_credentials: verify_credentials,
          friend_ids: friend_ids,
          follower_ids: follower_ids,
          users: users
      }
    end

    def inspect
      'verify_credentials ' + verify_credentials.inspect +
          ' friend_ids ' + friend_ids.inspect +
          ' follower_ids ' + follower_ids.inspect +
          ' users ' + users.inspect
    end

    private

    def extract_remaining_and_reset_in(limit)
      {remaining: limit[:remaining], reset_in: (Time.at(limit[:reset]) - Time.now).round}
    end
  end
end
