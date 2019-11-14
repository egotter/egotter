Datadog.configure do |c|
  c.use :rails, service_name: 'egotter'
  c.analytics_enabled = true
  c.runtime_metrics_enabled = true
end if Rails.env.production?
