class SendMetricsToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform
    send_table_metrics
    send_twitter_user_metrics
    send_google_analytics_metrics
    send_sidekiq_queue_metrics
    send_sidekiq_worker_metrics
    send_nginx_metrics
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

  def send_twitter_user_metrics
    friends_count = []
    followers_count = []
    friends_size = []
    followers_size = []
    TwitterUser.where(created_at: 1.hour.ago..Time.zone.now).each do |user|
      friends_count << user.friends_count
      followers_count << user.followers_count
      friends_size << user.friends_size
      followers_size << user.followers_size
    end
    size = friends_count.size

    stats = {
        friends_count: {
            size: size,
            avg: sprintf("%.1f", divide(friends_count.sum, size)),
            min: friends_count.min,
            max: friends_count.max
        },
        followers_count: {
            size: size,
            avg: sprintf("%.1f", divide(followers_count.sum, size)),
            min: followers_count.min,
            max: followers_count.max
        },
        friends_size: {
            size: size,
            avg: sprintf("%.1f", divide(friends_size.sum, size)),
            min: friends_size.min,
            max: friends_size.max
        },
        followers_size: {
            size: size,
            avg: sprintf("%.1f", divide(followers_size.sum, size)),
            min: followers_size.min,
            max: followers_size.max
        }
    }

    send_message(stats.to_s)
  end

  def send_google_analytics_metrics
    google_analytics = {'rt:activeUsers' => GoogleAnalyticsClient.new.active_users}
    send_message(google_analytics.to_s)
  end

  def send_sidekiq_queue_metrics
    queues =
        Sidekiq::Queue.all.select {|queue| queue.latency > 0}.map do |queue|
          [queue.name, {size: queue.size, latency: sprintf("%.3f", queue.latency)}].to_s
        end
    send_message(queues.join("\n"), channel: SIDEKIQ_MONITORING)
  end

  def send_sidekiq_worker_metrics
    %w(sidekiq sidekiq_import).each do |type|
      stats = SidekiqStats.new(type).map {|key, value| [key, value].to_s}
      send_message(stats.join("\n"), channel: SIDEKIQ_MONITORING)
    end
  end

  def send_nginx_metrics
    send_message(NginxStats.new.to_s)
  end

  URL = ENV['SLACK_METRICS_WEBHOOK_URL']
  SIDEKIQ_MONITORING = ENV['SLACK_SIDEKIQ_MONITORING_WEBHOOK_URL']

  def send_message(text, channel: URL)
    HTTParty.post(channel, body: {text: text}.to_json)
  end

  def divide(num1, num2)
    num1 / num2
  rescue ZeroDivisionError => e
    0
  end
end
