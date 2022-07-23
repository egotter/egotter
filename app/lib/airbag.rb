require 'forwardable'
require 'singleton'

class Airbag
  include Singleton

  def initialize
  end

  def debug(message = nil, props = {}, &block)
    log(::Logger::DEBUG, block_given? ? yield : message, props)
  end

  def info(message = nil, props = {}, &block)
    log(::Logger::INFO, block_given? ? yield : message, props)
  end

  def warn(message = nil, props = {}, &block)
    log(::Logger::WARN, block_given? ? yield : message, props)
  end

  def error(message = nil, props = {}, &block)
    log(::Logger::ERROR, block_given? ? yield : message, props)
  end

  def exception(e, props = {})
    props[:backtrace] = e.backtrace
    props[:cause_backtrace] = e.cause.backtrace if e.cause
    log(::Logger::ERROR, format_exception(e), props)
  end

  def log(level, raw_message, props)
    context = current_context
    message = format_message(level, raw_message, props, context)

    logger.add(level, message)

    if level >= logger.level
      CreateAirbagLogWorker.perform_async(
          format_severity(level), raw_message.to_s.truncate(50000), truncate_hash(context.merge(props)), Time.zone.now)
    end

    if @callbacks&.any?
      @callbacks.each do |blk|
        blk.call(level, raw_message, props, context)
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

  def current_context
    if Sidekiq.server?
      {
          env: Rails.env,
          tag: @tag,
          pid: ::Process.pid,
          tid: Thread.current["sidekiq_tid"],
          class: (Thread.current[:sidekiq_context][:class] rescue nil),

      }
    else
      {
          env: Rails.env,
          tag: @tag,
      }
    end
  rescue => e
    {}
  end

  def format_exception(e)
    "#{e.inspect.truncate(200)}#{" caused by #{e.cause.inspect.truncate(200)}" if e.cause}"
  end

  def format_message(level, message, props, context)
    "#{format_hash(context)} #{format_severity(level)}: #{message} #{format_hash(props)}"
  end

  def format_hash(hash)
    hash.except(:backtrace, :cause_backtrace, :caller).map { |k, v| "#{k}=#{v.inspect.truncate(200)}" }.join(' ')
  end

  def truncate_hash(hash)
    hash.transform_values { |v| v.is_a?(String) ? v.inspect.truncate(200) : v }
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
    def_delegators :instance, :debug, :info, :warn, :error, :exception, :benchmark, :broadcast, :format_hash, :truncate_hash, :tag=, :disable!, :format_severity
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
