class ApiClient
  def initialize(client)
    @client = client
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
