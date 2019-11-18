require 'datadog/statsd'

class SendMetricsToCloudWatchWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    30.seconds
  end

  # Run every minute
  def perform
    %i(send_google_analytics_metrics
       send_sidekiq_metrics
       send_prompt_reports_metrics
       send_search_error_logs_metrics).each do |method_name|
      send(method_name)
    rescue => e
      logger.warn "#{method_name} #{e.class} #{e.message}"
      logger.info e.backtrace.join("\n")
    end
  end

  # def datadog(values, ga_active_users, rate_limits)
  #   statsd = Datadog::Statsd.new('localhost', 8125)
  #
  #   values.each do |name, size, latency|
  #     statsd.gauge("sidekiq.queues.#{name}.size", size)
  #     statsd.gauge("sidekiq.queues.#{name}.latency", latency)
  #   end
  #   statsd.gauge('google.analytics.active_users', ga_active_users)
  #
  #   rate_limits.each do |rl|
  #     %i(verify_credentials friend_ids follower_ids).each do |endpoint|
  #       statsd.gauge("twitter.rate_limits.#{endpoint}.remaining", rl[endpoint][:remaining], tags: ["bot_id:#{rl[:id]}"])
  #     end
  #   end
  # end

  private

  def send_sidekiq_metrics
    # region = %x(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')
    # instance_id=%x(curl -s http://169.254.169.254/latest/meta-data/instance-id)

    namespace = "Sidekiq/#{Rails.env}"

    total = 0
    Sidekiq::Queue.all.each do |queue|
      next if queue.size == 0
      total += queue.size
      options = {namespace: namespace, dimensions: [{name: 'QueueName', value: queue.name}]}
      client.put_metric_data('QueueSize', queue.size, options)
      client.put_metric_data('QueueLatency', queue.latency, options)
    end

    options = {namespace: namespace, dimensions: [{name: 'QueueName', value: 'total'}]}
    client.put_metric_data('QueueSize', total, options)
  end

  def send_google_analytics_metrics
    namespace = "Google Analytics/#{Rails.env}"

    dimensions = [{name: 'rt:total', value: 'total'}]
    options = {namespace: namespace, dimensions: dimensions}
    client.put_metric_data('rt:activeUsers', GoogleAnalyticsClient.new.active_users, options)

    # There are many kinds of sources.
    # [["DESKTOP", "(none)", "(direct)", "NEW", "0"],
    #  ["DESKTOP", "ORGANIC", "google", "NEW", "0"],
    #  ["DESKTOP", "SOCIAL", "Twitter", "NEW", "0"],
    #  ["MOBILE", "(none)", "(direct)", "NEW", "0"],
    #  ["MOBILE", "ORGANIC", "google", "NEW", "0"],
    #  ["MOBILE", "SOCIAL", "Twitter", "NEW", "0"]]
    GoogleAnalyticsClient.new.realtime_data(
        metrics: %w(rt:activeUsers),
        dimensions: %w(rt:deviceCategory rt:medium rt:source rt:userType)
    ).rows.each do |device_category, medium, source, user_type, active_users|
      next if active_users.to_i <= 3
      dimensions = [
          {name: 'rt:deviceCategory', value: device_category},
          {name: 'rt:medium', value: medium},
          {name: 'rt:source', value: source},
          {name: 'rt:userType', value: user_type}
      ]

      options = {namespace: namespace, dimensions: dimensions}
      client.put_metric_data('rt:activeUsers', active_users, options)
    rescue => e
      logger.warn "#{e.class} #{e.message} #{device_category} #{medium} #{source} #{user_type} #{active_users}"
    end
  end

  def send_prompt_reports_metrics
    namespace = "PromptReports/#{Rails.env}"
    duration = {created_at: 10.minutes.ago..Time.zone.now}

    CreatePromptReportLog.where(duration).where.not(error_class: '').group(:error_class).count.each do |key, value|
      name = key.split('::').last
      options = {namespace: namespace, dimensions: [{name: 'ErrorName', value: name}]}
      client.put_metric_data('Count', value, options)
    end

    send_count = PromptReport.where(duration).size
    options = {namespace: namespace, dimensions: [{name: 'SendCount', value: 'SendCount'}]}
    client.put_metric_data('Count', send_count, options)

    read_count = PromptReport.where(duration).where.not(read_at: nil).size
    options = {namespace: namespace, dimensions: [{name: 'ReadCount', value: 'ReadCount'}]}
    client.put_metric_data('Count', read_count, options)

    read_rate = 100.0 * read_count / send_count
    options = {namespace: namespace, dimensions: [{name: 'ReadRate', value: 'ReadRate'}]}
    client.put_metric_data('Rate', read_rate, options)
  end

  def send_search_error_logs_metrics
    namespace = "SearchErrorLogs/#{Rails.env}"
    duration = {created_at: 30.minutes.ago..Time.zone.now}

    SearchErrorLog.where(duration).where.not(device_type: 'crawler').where(user_id: -1).group(:location).count.each do |key, value|
      options = {namespace: namespace, dimensions: [{name: 'Location', value: key}, {name: 'Sign in', value: 'false'}]}
      client.put_metric_data('Count', value, options)
    end

    SearchErrorLog.where(duration).where.not(device_type: 'crawler').where.not(user_id: -1).group(:location).count.each do |key, value|
      options = {namespace: namespace, dimensions: [{name: 'Location', value: key}, {name: 'Sign in', value: 'true'}]}
      client.put_metric_data('Count', value, options)
    end
  end

  def send_create_twitter_user_logs_metrics
    namespace = "CreateTwitterUserLogs/#{Rails.env}"
    duration = {created_at: 30.minutes.ago..Time.zone.now}

    CreateTwitterUserLog.where(duration).where(user_id: -1).where.not(error_class: nil).group(:error_class).count.each do |key, value|
      name = key.split('::').last
      options = {namespace: namespace, dimensions: [{name: 'ErrorName', value: name}, {name: 'Sign in', value: 'false'}]}
      client.put_metric_data('Count', value, options)
    end

    CreateTwitterUserLog.where(duration).where.not(user_id: -1).where.not(error_class: nil).group(:error_class).count.each do |key, value|
      name = key.split('::').last
      options = {namespace: namespace, dimensions: [{name: 'ErrorName', value: name}, {name: 'Sign in', value: 'true'}]}
      client.put_metric_data('Count', value, options)
    end
  end

  private

  def client
    @client ||= CloudWatchClient.new
  end
end
