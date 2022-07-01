require 'singleton'

class Airbag
  class << self
    def debug(message = nil, &block)
      log(Logger::DEBUG, message, &block)
    end

    def info(message = nil, &block)
      log(Logger::INFO, message, &block)
    end

    def warn(message = nil, &block)
      log(Logger::WARN, message, &block)
    end

    def log(level, message = nil, &block)
      message = yield if message.nil? && block_given?
      logger.add(level, message)
    ensure
      if level > Logger::DEBUG
        CreateAirbagLogWorker.perform_async(format_severity(level), message, nil, Time.zone.now)
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

    SEV_LABEL = %w(DEBUG INFO WARN ERROR FATAL ANY).freeze

    def format_severity(severity)
      SEV_LABEL[severity] || 'ANY'
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
