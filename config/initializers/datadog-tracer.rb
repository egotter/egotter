if Rails.env.production?
  require 'datadog/statsd'
  require 'ddtrace'

  Datadog.configure do |c|
    c.use :rails, service_name: 'egotter'
    c.use :sidekiq
    c.analytics_enabled = true
    c.runtime_metrics_enabled = true
  end
end
