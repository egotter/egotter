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
          :send_search_histories_metrics,
          :send_visitors_metrics,
          :send_sign_in_metrics,
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

  def send_table_metrics
    name = 'tables'
    SlackClient.table_monitoring.send_message(fetch_gauges(name, :sum), title: name)
  end

  def send_twitter_user_metrics
    [
        'twitter_user',
        'twitter_user friends_count',
        'twitter_user followers_count',
        'twitter_user friends_size',
        'twitter_user followers_size',
    ].each do |name|
      SlackClient.twitter_users_monitoring.send_message(fetch_gauges(name, :average), title: name)
    end
  end

  def send_sidekiq_queue_metrics
    names = Gauge.where(time: 10.minutes.ago..Time.zone.now).where('name like "sidekiq_queue %"').pluck(:name).uniq
    names.each do |name|
      SlackClient.sidekiq_monitoring.send_message(fetch_gauges(name, :average), title: name)
    end
  end

  def send_sidekiq_worker_metrics
    names = Gauge.where(time: 10.minutes.ago..Time.zone.now).where('name like "sidekiq_worker %"').pluck(:name).uniq
    names.each do |name|
      SlackClient.sidekiq_monitoring.send_message(fetch_gauges(name, :average), title: name)
    end
  end

  def send_search_histories_metrics
    [
        'search_histories',
        'search_histories via',
        'search_histories source',
        'search_histories device_type',
    ].each do |name|
      SlackClient.search_histories_monitoring.send_message(fetch_gauges(name, :sum), title: name)
    end
  end

  def send_visitors_metrics
    [
        'visitors',
        'visitors via',
        'visitors source',
        'visitors device_type',
    ].each do |name|
      SlackClient.visitors_monitoring.send_message(fetch_gauges(name, :sum), title: name)
    end
  end

  def send_user_metrics
    [
        'users',
        'users via',
        'users source',
        'users device_type',
    ].each do |name|
      SlackClient.users_monitoring.send_message(fetch_gauges(name, :sum), title: name)
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
      SlackClient.sign_in_monitoring.send_message(fetch_gauges(name, :sum), title: name)
    end
  end

  def send_rate_limit_metrics
    stats =
        Bot.rate_limit.map do |limit|
          id = limit.delete(:id).to_s
          values = limit.map {|key, value| [key, value[:remaining]]}.to_h
          [id, values]
        end.to_h

    SlackClient.rate_limit_monitoring.send_message(stats)
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
      SlackClient.search_error_monitoring.send_message(fetch_gauges(name, :sum), title: name)
    end
  end

  private

  def fetch_gauges(name, aggregation)
    if %i(sum average).include?(aggregation)
      Gauge.where(time: 1.hour.ago..Time.zone.now).where(name: name).group('label').send(aggregation, 'value').sort_by {|_, v| -v}.to_h
    else
      raise "Invalid aggregation #{aggregation}"
    end
  end
end
