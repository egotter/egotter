require 'active_support/concern'

module CredentialsApi
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def api_client(options = {})
    ::ApiClient.instance(options.merge(access_token: token, access_token_secret: secret))
  end

  def rate_limit
    RateLimitClient.new(api_client.twitter).rate_limit
  end

  class RateLimitClient
    def initialize(client)
      @client = client
    end

    def rate_limit
      retries ||= 3
      path = '/1.1/application/rate_limit_status.json'
      request = Twitter::REST::Request.new(@client, :get, path, {})
      RateLimit.new(request.perform)
    rescue => e
      if ServiceStatus.retryable_error?(e)
        if (retries -= 1) > 0
          retry
        else
          raise RetryExhausted.new(e.inspect)
        end
      else
        raise
      end
    end

    class RetryExhausted < StandardError; end
  end

  class RateLimit
    def initialize(status)
      @status = status
    end

    def resources
      @status[:resources]
    end

    def context
      @status[:rate_limit_context]
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
