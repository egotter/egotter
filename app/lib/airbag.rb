require 'singleton'

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

    # options:
    #   level, silence, slow_duration
    def benchmark(message = "Benchmarking", options = {})
      options[:level] ||= :info
      options[:slow_duration] ||= 100

      result = nil
      ms = Benchmark.ms { result = options[:silence] ? logger.silence { yield } : yield }

      if ms > options[:slow_duration]
        logger.public_send(options[:level], "%s (%.1fms)" % [message, ms])
      end

      result
    end

    def logger
      @logger ||= Logger.instance
    end

    def disable!
      @logger = ::Logger.new(nil)
    end
  end

  class Logger < ::Logger
    include Singleton

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
