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
      unless @logger
        MX.synchronize do
          @logger = Logger.new
        end
      end
      @logger
    end
  end

  class Logger < ::Logger
    def initialize
      super('log/airbag.log')
      self.level = Logger::INFO
      self.datetime_format = '%Y-%m-%d %H:%M:%S'
      self.formatter = Proc.new do |severity, timestamp, _, msg|
        "#{severity[0]}, [#{timestamp}] #{severity} -- [Airbag] #{msg}\n"
      end
    end
  end
end
