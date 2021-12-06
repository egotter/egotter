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
          :send_search_histories_metrics,
          :send_error_pages_metrics,
      ]
    end

    do_perform(steps.shift)
    self.class.perform_async(steps) if steps.any?
  end

  def do_perform(step)
    send(step)
  rescue => e
    Airbag.warn "#{e.class} #{e.message} #{step}"
    Airbag.info e.backtrace.join("\n")
  end

  def send_table_metrics
    name = 'tables'
    SlackClient.table_monitoring.send_message(fetch_gauges(name, :sum), title: name)
  end

  def send_twitter_user_metrics
    records = TwitterUser.where(created_at: 1.hours.ago..Time.zone.now)
    message = "count=#{records.size} count(distinct uid)=#{records.select('distinct uid').count} count(distinct user_id)=#{records.select('distinct user_id').count}"
    SendMessageToSlackWorker.perform_async(:twitter_users_monitoring, message)
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
    records = SearchHistory.where(created_at: 24.hours.ago..Time.zone.now)
    message = "count=#{records.size} count(distinct uid)=#{records.select('distinct uid').count} count(distinct user_id)=#{records.select('distinct user_id').count}"
    SendMessageToSlackWorker.perform_async(:search_histories_monitoring, message)
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
    records = User.where(created_at: 1.hours.ago..Time.zone.now)
    message = "count=#{records.size}"
    SendMessageToSlackWorker.perform_async(:users_monitoring, message)
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

  def send_search_error_metrics
    records = SearchErrorLog.where(created_at: 1.hours.ago..Time.zone.now).group(:location).count
    message = records.any? ? records.map { |k, v| "#{k}=#{v}" }.join(' ') : 'empty'
    SendMessageToSlackWorker.perform_async(:search_error_monitoring, message)
  end

  def send_error_pages_metrics
    records = SearchLog.where(created_at: 24.hours.ago..Time.zone.now).where(controller: 'error_pages').group(:action).count
    message = records.any? ? records.sort_by { |_, v| -v }.map { |k, v| "#{k}=#{v}" }.join("\n") : 'empty'
    SendMessageToSlackWorker.perform_async(:search_error_monitoring, message)
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
