require 'singleton'

class Airbag
  class << self
    def debug(message = nil, props = {}, &block)
      log(Logger::DEBUG, message, props, &block)
    end

    def info(message = nil, props = {}, &block)
      log(Logger::INFO, message, props, &block)
    end

    def warn(message = nil, props = {}, &block)
      log(Logger::WARN, message, props, &block)
    end

    def error(message = nil, props = {}, &block)
      log(Logger::ERROR, message, props, &block)
    end

    def log(level, message = nil, props = {}, &block)
      message = yield if message.nil? && block_given?
      message = "#{format_context}#{format_severity(level)}: #{message}"
      logger.add(level, message)

      if level > Logger::DEBUG
        CreateAirbagLogWorker.perform_async(format_severity(level), message, props, Time.zone.now)
      end

      if @slack && level > @slack[:level]
        SendMessageToSlackWorker.perform_async(@slack[:channel], message.truncate(1000))
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

    def broadcast(options)
      if options[:target] == :slack
        @slack = {channel: options[:channel], tag: options[:tag], level: options[:level]}
      end
    end

    def format_context
      if Sidekiq.server?
        ctx = {
            env: Rails.env,
            tag: @slack && @slack[:tag],
            pid: ::Process.pid,
            tid: Thread.current["sidekiq_tid"],
            class: (Thread.current[:sidekiq_context][:class] rescue nil),

        }
      else
        ctx = {
            env: Rails.env,
            tag: @slack && @slack[:tag],
        }
      end

      if ctx.any?
        ctx.compact.map { |k, v| "#{k}=#{v}" }.join(' ') + ' '
      end
    rescue => e
      ''
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
