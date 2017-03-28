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
    region = %x(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')
    instance_id=%x(curl -s http://169.254.169.254/latest/meta-data/instance-id)

    values.each do |name, size, latency|
      options = {
        namespace: 'egotter',
        dimensions: {QueueName: name}.map { |k, v| "#{k}=#{v}" }.join(','),
        unit: 'Count',
        region: region,
      }

      size_options = {'metric-name' => 'QueueSize', value: size}.merge(options).map { |n, v| "--#{n} #{v}" }.join ' '
      latency_options = {'metric-name' => 'QueueLatency', value: latency}.merge(options).map { |n, v| "--#{n} #{v}" }.join ' '

      %x(aws cloudwatch put-metric-data #{size_options})
      %x(aws cloudwatch put-metric-data #{latency_options})
    end

    options = {namespace: 'google/analytics', unit: 'Count', region: region, 'metric-name' => 'ActiveUsers', value: ga_active_users}
      .map { |n, v| "--#{n} #{v}" }.join ' '
    %x(aws cloudwatch put-metric-data #{options})
  end
end
