require 'datadog/statsd'

class SendMetricsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform
    values = [
      CreateTwitterUserWorker,
      CreateSignedInTwitterUserWorker,
      DelayedCreateTwitterUserWorker,
      ImportTwitterUserRelationsWorker,
      DelayedImportTwitterUserRelationsWorker
    ].map do |klass|
      name = klass.name
      queue = Sidekiq::Queue.new(name)
      [name, queue.size, queue.latency]
    end

    begin
      ga_active_users = GoogleAnalyticsClient.new.active_users
    rescue => e
      logger.warn "#{e.class} #{e.message}"
      ga_active_users = 0
    end

    datadog(values, ga_active_users)
    cloudwatch(values, ga_active_users)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
  ensure
    SendMetricsWorker.perform_in(1.minute.since)
  end

  def datadog(values, ga_active_users)
    statsd = Datadog::Statsd.new('localhost', 8125)
    values.each do |name, size, latency|
      statsd.gauge("sidekiq.queues.#{name}.size", size)
      statsd.gauge("sidekiq.queues.#{name}.latency", latency)
    end
    statsd.gauge('google.analytics.active_users', ga_active_users)
  end

  def cloudwatch(values, ga_active_users)
    # region = %x(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')
    # instance_id=%x(curl -s http://169.254.169.254/latest/meta-data/instance-id)

    client = CloudwatchClient.new

    values.each do |name, size, latency|
      options = {namespace: 'egotter', dimensions: [{name: 'QueueName', value: name}]}
      client.put_metric_data('QueueSize', size, options)
      client.put_metric_data('QueueLatency', latency, options)
    end

    client.put_metric_data('ActiveUsers', ga_active_users, namespace: 'google/analytics')
  end
end
