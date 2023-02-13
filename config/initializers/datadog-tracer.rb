if Rails.env.production?
  require 'datadog/statsd'
  require 'ddtrace'

  # Datadog APM
  Datadog.configure do |c|
    logger = ::Logger.new('log/datadog-tracer.log')
    logger.level = ::Logger::INFO
    c.logger.instance = logger

    c.tracing.instrument :rails, service_name: 'egotter'
    c.tracing.instrument :sidekiq
    c.tracing.analytics.enabled = true
    c.tracing.partial_flush.enabled = true
    c.runtime_metrics.enabled = true
  end
end
