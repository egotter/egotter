class Airbag
  class << self
    def info(message = nil, &block)
      log(Logger::INFO, message, &block)
    end

    def warn(message = nil, &block)
      log(Logger::WARN, message, &block)
    end

    def log(level, message = nil, &block)
      if block_given?
        logger.add(level) { "[Airbag] #{yield}" }
      else
        logger.add(level) { "[Airbag] #{message}" }
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
