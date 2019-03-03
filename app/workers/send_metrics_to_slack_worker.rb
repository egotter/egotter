class SendMetricsToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform
    send_table_metrics
    send_google_analytics_metrics
    send_sidekiq_queue_metrics
    send_sidekiq_worker_metrics
  rescue => e
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end

  def send_table_metrics
    logs_count =
        [SearchLog, SignInLog, TwitterUser, SearchHistory, Job].map do |klass|
          [klass.to_s, klass.where(created_at: 1.hour.ago..Time.zone.now).size]
        end.to_h
    send_message(logs_count.to_s)
  end

  def send_google_analytics_metrics
    google_analytics = {'rt:activeUsers' => GoogleAnalyticsClient.new.active_users}
    send_message(google_analytics.to_s)
  end

  def send_sidekiq_queue_metrics
    queues =
        Sidekiq::Queue.all.select {|queue| queue.latency > 0}.map do |queue|
          [queue.name, {size: queue.size, latency: queue.latency}].to_s
        end
    send_message(queues.join("\n"))
  end

  def send_sidekiq_worker_metrics
    stats = SidekiqStats.new('sidekiq_misc').map {|key, value| [key, value].to_s}
    send_message(stats.join("\n"))
  end

  def send_nginx_metrics
    send_message(NginxStats.new.to_s)
  end

  URL = ENV['SLACK_METRICS_WEBHOOK_URL']

  def send_message(text)
    HTTParty.post(URL, body: {text: text}.to_json)
  end
end
