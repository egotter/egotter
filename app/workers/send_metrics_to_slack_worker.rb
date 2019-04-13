class SendMetricsToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(steps = nil)
    steps.inspect
  end

  def unique_in
    5.minutes
  end

  def perform(steps = nil)
    unless steps
      steps = [
          :send_table_metrics,
          :send_user_metrics,
          :send_twitter_user_metrics,
          :send_google_analytics_metrics,
          :send_sidekiq_queue_metrics,
          :send_sidekiq_worker_metrics,
          :send_nginx_metrics,
          :send_search_histories_metrics,
          :send_visitors_metrics,
          :send_sign_in_metrics,
          :send_prompt_report_metrics,
          :send_prompt_report_error_metrics,
          :send_rate_limit_metrics,
          :send_search_error_metrics,
      ]
    end

    do_perform(steps.shift)
    self.class.perform_async(steps) if steps.any?
  end

  def do_perform(step)
    send(step)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{step}"
    logger.info e.backtrace.join("\n")
  end

  def fetch_gauges(name, aggregation)
    if %i(sum average).include?(aggregation)
      Gauge.where(time: 1.hour.ago..Time.zone.now).where(name: name).group('label').send(aggregation, 'value').sort_by {|_, v| -v}.to_h
    else
      raise "Invalid aggregation #{aggregation}"
    end
  end

  def send_table_metrics
    name = 'tables'
    SlackClient.send_message(fetch_gauges(name, :sum), title: name, channel: SlackClient::TABLE_MONITORING)
  end

  def send_twitter_user_metrics
    [
        'twitter_user',
        'twitter_user friends_count',
        'twitter_user followers_count',
        'twitter_user friends_size',
        'twitter_user followers_size',
    ].each do |name|
      SlackClient.send_message(fetch_gauges(name, :sum), title: name, channel: SlackClient::TWITTER_USERS_MONITORING)
    end
  end

  def send_google_analytics_metrics
    name = 'ga rt:activeUsers'
    value = Gauge.order(created_at: :desc).find_by(name: name).value
    SlackClient.send_message(value, title: name, channel: SlackClient::GA_MONITORING)
  end

  def send_prompt_report_metrics
    name = 'prompt_report'
    SlackClient.send_message(fetch_gauges(name, :sum), title: name, channel: SlackClient::MESSAGING_MONITORING)
  end

  def send_prompt_report_error_metrics
    name = 'prompt_report_error'
    SlackClient.send_message(fetch_gauges(name, :sum), title: name, channel: SlackClient::MESSAGING_MONITORING)
  end

  def send_sidekiq_queue_metrics
    names = Gauge.where(time: 10.minutes.ago..Time.zone.now).where('name like "sidekiq_queue %"').pluck(:name).uniq
    names.each do |name|
      SlackClient.send_message(fetch_gauges(name, :average), title: name, channel: SlackClient::SIDEKIQ_MONITORING)
    end
  end

  def send_sidekiq_worker_metrics
    names = Gauge.where(time: 10.minutes.ago..Time.zone.now).where('name like "sidekiq_worker %"').pluck(:name).uniq
    names.each do |name|
      SlackClient.send_message(fetch_gauges(name, :average), title: name, channel: SlackClient::SIDEKIQ_MONITORING)
    end
  end

  def send_nginx_metrics
    name = 'nginx'
    SlackClient.send_message(fetch_gauges(name, :average), title: name, channel: SlackClient::MONITORING)
  end

  def send_search_histories_metrics
    [
        'search_histories',
        'search_histories via',
        'search_histories source',
        'search_histories device_type',
    ].each do |name|
      SlackClient.send_message(fetch_gauges(name, :sum), title: name, channel: SlackClient::SEARCH_HISTORIES_MONITORING)
    end
  end

  def send_visitors_metrics
    [
        'visitors',
        'visitors via',
        'visitors source',
        'visitors device_type',
    ].each do |name|
      SlackClient.send_message(fetch_gauges(name, :sum), title: name, channel: SlackClient::VISITORS_MONITORING)
    end
  end

  def send_user_metrics
    [
        'users',
        'users via',
        'users source',
        'users device_type',
    ].each do |name|
      SlackClient.send_message(fetch_gauges(name, :sum), title: name, channel: SlackClient::USERS_MONITORING)
    end
  end

  def send_sign_in_metrics
    [
        'sign_in',
        'sign_in via',
        'sign_in via (create)',
        'sign_in via (update)',
        'sign_in source',
        'sign_in device_type',
    ].each do |name|
      SlackClient.send_message(fetch_gauges(name, :sum), title: name, channel: SlackClient::SIGN_IN_MONITORING)
    end
  end

  def send_rate_limit_metrics
    stats =
        Bot.rate_limit.map do |limit|
          id = limit.delete(:id).to_s
          values = limit.map {|key, value| [key, value[:remaining]]}.to_h
          [id, values]
        end.to_h

    SlackClient.send_message(stats, channel: SlackClient::RATE_LIMIT_MONITORING)
  end

  def send_search_error_metrics
    [
        'search_error location',
        'search_error location (user)',
        'search_error location (visitor)',
        'search_error via',
        'search_error source',
        'search_error device_type',
    ].each do |name|
      SlackClient.send_message(fetch_gauges(name, :sum), title: name, channel: SlackClient::SEARCH_ERROR_MONITORING)
    end
  end
end
