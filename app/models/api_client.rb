require 'active_support/cache/redis_cache_store'

class ApiClient
  def initialize(client)
    @client = client
  end

  def create_direct_message_event(*args)
    tries ||= 3
    resp = @client.twitter.create_direct_message_event(*args).to_h
    DirectMessage.new(event: resp)
  rescue => e
    if ServiceStatus.connection_reset_by_peer?(e) && (tries -= 1) > 0
      retry
    else
      raise
    end
  end

  def method_missing(method, *args, &block)
    if @client.respond_to?(method)
      logger.debug { "ApiClient#method_missing #{method} #{args.inspect.truncate(100)}" } rescue nil
      self.class.do_request_with_retry(@client, method, args, &block)
    else
      super
    end
  end

  class << self
    # TODO Want to refactor
    def do_request_with_retry(client, method, args, &block)
      tries ||= 5
      client.send(method, *args, &block) # client#parallel uses block.
    rescue Twitter::Error::Unauthorized => e
      if AccountStatus.unauthorized?(e)
        user = User.select(:id).find_by(token: client.access_token, secret: client.access_token_secret)
        UpdateAuthorizedWorker.perform_async(user.id, enqueued_at: Time.zone.now) if user
      end

      raise
    rescue => e
      logger.info "#{__method__} #{e.inspect} #{method} #{args.inspect.truncate(100)}"
      if ServiceStatus.new(ex: e).retryable?
        if (tries -= 1) < 0
          logger.warn "RETRY EXHAUSTED #{self}##{method}: #{e.class} #{e.message}"
          raise
        else
          retry
        end
      else
        raise
      end
    end

    def config(options = {})
      {
          consumer_key: ENV['TWITTER_CONSUMER_KEY'],
          consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
          access_token: nil,
          access_token_secret: nil
      }.merge(options)
    end

    def instance(options = {})
      client =
          if options.blank?
            TwitterWithAutoPagination::Client.new
          else
            options[:cache_store] = CacheStore.new
            TwitterWithAutoPagination::Client.new(config(options))
          end
      new(client)
    end

    def logger
      Rails.logger
    end
  end

  private

  def logger
    self.class.logger
  end

  class CacheStore < ActiveSupport::Cache::RedisCacheStore
    def initialize
      super(
          namespace: "#{Rails.env}:twitter",
          expires_in: 20.minutes,
          race_condition_ttl: 3.minutes,
          redis: self.class.redis_client
      )
    end

    class << self
      # Intentionally not cached
      def redis_client
        Redis.client(ENV['TWITTER_API_REDIS_HOST'])
      end
    end

    module RescueAllRedisErrors
      %i(
        read
        write
      ).each do |method_name|
        define_method(method_name) do |*args, &blk|
          super(*args, &blk)
        rescue => e
          Rails.logger.warn "Rescue all errors in #{self.class}##{method_name} #{e.inspect}"
          nil
        end
      end
    end
    prepend RescueAllRedisErrors
  end
end
