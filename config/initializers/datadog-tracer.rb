if Rails.env.production?
  require 'datadog/statsd'
  require 'ddtrace'

  # Datadog APM
  Datadog.configure do |c|
    c.logger = ::Logger.new('log/datadog-tracer.log')
    c.logger.level = ::Logger::INFO

    c.use :rails, service_name: 'egotter'
    c.use :sidekiq
    c.analytics_enabled = true
    c.runtime_metrics_enabled = true
  end
end
