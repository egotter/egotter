require 'forwardable'
require 'singleton'

class Airbag
  include Singleton

  def initialize
  end

  def debug(message = nil, props = {}, &block)
    log(::Logger::DEBUG, message, props, &block)
  end

  def info(message = nil, props = {}, &block)
    log(::Logger::INFO, message, props, &block)
  end

  def warn(message = nil, props = {}, &block)
    log(::Logger::WARN, message, props, &block)
  end

  def error(message = nil, props = {}, &block)
    log(::Logger::ERROR, message, props, &block)
  end

  def exception(e, props = {})
    message = "#{e.inspect.truncate(200)}#{' ' + format_hash(props) if props.any?}"
    log(::Logger::ERROR, message, props.merge(backtrace: e.backtrace))
  end

  def log(level, raw_message = nil, props = {}, &block)
    message = raw_message.nil? && block_given? ? yield : raw_message
    message = format_message(level, message)

    logger.add(level, message)

    if level >= logger.level
      CreateAirbagLogWorker.perform_async(format_severity(level), message.truncate(50000), props, Time.zone.now)
    end

    if @callbacks&.any?
      @callbacks.each do |blk|
        blk.call(level, raw_message, message, props)
      end
    end

    true
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

  def broadcast(&block)
    (@callbacks ||= []) << block
  end

  def format_message(level, message)
    "#{format_context}#{format_severity(level)}: #{message}"
  end

  def format_context
    if Sidekiq.server?
      ctx = {
          env: Rails.env,
          tag: @tag,
          pid: ::Process.pid,
          tid: Thread.current["sidekiq_tid"],
          class: (Thread.current[:sidekiq_context][:class] rescue nil),

      }
    else
      ctx = {
          env: Rails.env,
          tag: @tag,
      }
    end

    if ctx.any?
      format_hash(ctx) + ' '
    end
  rescue => e
    ''
  end

  def format_hash(hash)
    hash.compact.map { |k, v| "#{k}=#{v.to_s.truncate(100)}" }.join(' ')
  end

  def tag=(value)
    @tag = value
  end

  def logger
    @logger ||= Logger.instance
  end

  def disable!
    @logger = ::Logger.new(nil)
    @callbacks = []
  end

  SEV_LABEL = %w(DEBUG INFO WARN ERROR FATAL ANY).freeze

  def format_severity(severity)
    SEV_LABEL[severity] || 'ANY'
  end

  class << self
    extend Forwardable
    def_delegators :instance, :debug, :info, :warn, :error, :exception, :benchmark, :broadcast, :tag=, :disable!
  end

  class Logger < ::Logger
    include Singleton

    def initialize
      super('log/airbag.log')
      self.level = Logger::INFO
      self.datetime_format = '%Y-%m-%d %H:%M:%S'
      self.formatter = Proc.new do |severity, timestamp, _, msg|
        "#{severity[0]}, [#{timestamp}] #{severity} -- #{msg}\n"
      end
    end
  end
end
