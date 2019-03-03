class SendMetricsToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform
    counts = [SearchLog, SignInLog, TwitterUser, SearchHistory, Job].map do |klass|
      [klass.to_s, klass.where(created_at: 1.hour.ago..Time.zone.now).size]
    end.to_h

    counts['rt:activeUsers'] = GoogleAnalyticsClient.new.active_users

    send_message(counts.to_s)
  rescue => e
    logger.warn "#{e.class}: #{e.message}"
    logger.info e.backtrace.join("\n")
  end

  URL = ENV['SLACK_METRICS_WEBHOOK_URL']

  def send_message(text)
    HTTParty.post(URL, body: {text: text}.to_json)
  end
end
