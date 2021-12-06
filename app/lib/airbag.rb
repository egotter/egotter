class Airbag
  class << self
    def warn(message = nil, &block)
      if block_given?
        logger.warn { "[Airbag] #{yield}" }
      else
        logger.warn { "[Airbag] #{message}" }
      end
    end

    def logger
      if Sidekiq.server?
        Sidekiq.logger
      else
        Rails.logger
      end
    end
  end
end
