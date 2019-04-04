class ApiClient
  def initialize(client)
    @client = client
  end

  def method_missing(method, *args, &block)
    if @client.respond_to?(method)
      logger.info "ApiClient#method_missing #{method} #{args.inspect.truncate(100)}" rescue nil
      self.class.do_request_with_retry(@client, method, args, &block)
    else
      super
    end
  end

  class << self
    def do_request_with_retry(client, method, args, &block)
      tries ||= 5
      client.send(method, *args, &block) # client#parallel uses block.
    rescue Twitter::Error::Unauthorized => e
      if e.message == 'Invalid or expired token.'
        user = User.select(:id).find_by(token: client.access_token, secret: client.access_token_secret)
        UpdateAuthorizedWorker.perform_async(user.id, enqueued_at: Time.zone.now) if user
      end

      raise
    rescue HTTP::ConnectionError,
        Twitter::Error::InternalServerError,
        Twitter::Error::ServiceUnavailable,
        Twitter::Error => e
      if retryable_exception?(e)
        message = "#{self.class}##{method}: #{e.class} #{e.message}"

        if (tries -= 1) < 0
          logger.warn "RETRY EXHAUSTED #{message}"
          raise
        else
          retry
        end
      else
        raise
      end
    end

    def retryable_exception?(ex)
      ([HTTP::ConnectionError, Twitter::Error].include?(ex.class) && ex.message.include?('Connection reset by peer')) ||
          (ex.class == Twitter::Error::InternalServerError && ex.message == 'Internal error') ||
          (ex.class == Twitter::Error::InternalServerError && ex.message == '') ||
          (ex.class == Twitter::Error::ServiceUnavailable && ex.message == 'Over capacity') ||
          (ex.class == Twitter::Error::ServiceUnavailable && ex.message == '') ||
          (ex.class == Twitter::Error && ex.message == 'execution expired')
    end

    def config(options = {})
      {
          consumer_key: ENV['TWITTER_CONSUMER_KEY'],
          consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
          access_token: nil,
          access_token_secret: nil,
          cache_dir: CacheDirectory.find_by(name: 'twitter')&.dir || ENV['TWITTER_CACHE_DIR']
      }.merge(options)
    end

    def instance(options = {})
      client =
          if options.blank?
            TwitterWithAutoPagination::Client.new
          else
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
end
