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
        logger.add(level, &block)
      else
        logger.add(level, message)
      end
    end

    MX = Mutex.new

    def logger
      MX.synchronize do
        unless @logger
          @logger = ActiveSupport::Logger.new('log/airbag.log')
          @logger.level = Logger::INFO
          @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
          @logger.formatter = Proc.new do |severity, timestamp, _, msg|
            "[#{timestamp}] #{severity} -- [Airbag] #{msg}\n"
          end

          app_logger = Sidekiq.server? ? Sidekiq.logger : Rails.logger
          @logger.extend ActiveSupport::Logger.broadcast(app_logger)
        end
      end
      @logger
    end
  end
end
