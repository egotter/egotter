require 'datadog/statsd'

class SendMetricsToCloudWatchWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    30.seconds
  end

  def timeout_in
    50.seconds
  end

  # Run every minute
  def perform
    %i(send_google_analytics_metrics
       send_periodic_reports_metrics
       send_create_periodic_report_requests_metrics
       send_search_error_logs_metrics
       send_twitter_db_users_metrics
       send_search_histories_metrics
       send_sign_in_logs_metrics
       send_requests_metrics
       send_bots_metrics
    ).each do |method_name|
      send(method_name)
    rescue => e
      logger.warn "#{method_name} #{e.class} #{e.message}"
      notify_airbrake(e, method_name: method_name)
    end

    client.update
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
      put_metric_data('QueueSize', queue.size, options)
      put_metric_data('QueueLatency', queue.latency, options)
    end

    options = {namespace: namespace, dimensions: [{name: 'QueueName', value: 'total'}]}
    put_metric_data('QueueSize', total, options) if total > 0

    duration = 10.minutes
    long_running_jobs = []
    Sidekiq::Workers.new.each do |pid, tid, work|
      if Time.zone.at(work['run_at']) < duration.ago
        long_running_jobs << work['payload']['class']
      end
    end

    long_running_jobs.group_by { |name| name }.map { |k, v| [k, v.length] }.each do |job_name, count|
      dimensions = [{name: 'JobName', value: job_name}, {name: 'RunningTime', value: "more than #{duration.inspect}"}] # "10 minutes"
      options = {namespace: namespace, dimensions: dimensions}
      put_metric_data('LongRunningSize', count, options)
    end
  end

  def send_google_analytics_metrics
    namespace = "Google Analytics/#{Rails.env}"

    dimensions = [{name: 'rt:total', value: 'total'}]
    options = {namespace: namespace, dimensions: dimensions}
    begin
      active_users = GoogleAnalyticsClient.new.active_users
      put_metric_data('rt:activeUsers', active_users, options)
    rescue => e
      logger.warn "#{e.class} #{e.message} active_users=#{active_users} options=#{options.inspect}"
    end

    # There are many kinds of sources.
    # [["DESKTOP", "(none)", "(direct)", "NEW", "0"],
    #  ["DESKTOP", "ORGANIC", "google", "NEW", "0"],
    #  ["DESKTOP", "SOCIAL", "Twitter", "NEW", "0"],
    #  ["MOBILE", "(none)", "(direct)", "NEW", "0"],
    #  ["MOBILE", "ORGANIC", "google", "NEW", "0"],
    #  ["MOBILE", "SOCIAL", "Twitter", "NEW", "0"]]
    #GoogleAnalyticsClient.new.realtime_data(
    #    metrics: %w(rt:activeUsers),
    #    dimensions: %w(rt:deviceCategory rt:medium rt:source rt:userType)
    #).rows.each do |device_category, medium, source, user_type, active_users|
    #  next if active_users.to_i <= 3
    #  dimensions = [
    #      {name: 'rt:deviceCategory', value: device_category},
    #      {name: 'rt:medium', value: encode(medium)},
    #      {name: 'rt:source', value: encode(source)},
    #      {name: 'rt:userType', value: user_type}
    #  ]
    #
    #  options = {namespace: namespace, dimensions: dimensions}
    #  put_metric_data('rt:activeUsers', active_users, options)
    #rescue => e
    #  logger.warn "#{e.class} #{e.message} device_category=#{device_category} medium=#{encode(medium)} source=#{encode(source)} user_type=#{user_type} active_users=#{active_users}"
    #end
  end

  def send_periodic_reports_metrics
    namespace = "#{PeriodicReport.name.pluralize}#{"/#{Rails.env}" unless Rails.env.production?}"

    [1.minute, 10.minutes, 1.hour].each do |duration|
      condition = {created_at: duration.ago..Time.zone.now}

      send_count = PeriodicReport.where(condition).size
      options = {namespace: namespace, dimensions: [{name: 'Duration', value: duration.inspect}, {name: 'Type', value: 'Total'}]}
      put_metric_data('SendCount', send_count, options) if send_count > 0

      read_count = PeriodicReport.where(condition).where.not(read_at: nil).size
      options = {namespace: namespace, dimensions: [{name: 'Duration', value: duration.inspect}, {name: 'Type', value: 'Total'}]}
      put_metric_data('ReadCount', read_count, options) if read_count > 0

      if send_count > 0 && read_count > 0
        read_rate = 100.0 * read_count / send_count
        options = {namespace: namespace, dimensions: [{name: 'Duration', value: duration.inspect}, {name: 'Type', value: 'Total'}]}
        put_metric_data('ReadRate', read_rate, options)
      end
    end
  end

  def send_create_periodic_report_requests_metrics
    namespace = "#{CreatePeriodicReportRequest.name.pluralize}#{"/#{Rails.env}" unless Rails.env.production?}"

    [1.minute, 10.minutes, 1.hour].each do |duration|
      condition = {created_at: duration.ago..Time.zone.now}

      CreatePeriodicReportRequest.where(condition).group(:status).count.each do |status, count|
        next if status.blank?
        options = {namespace: namespace, dimensions: [{name: 'Duration', value: duration.inspect}]}
        put_metric_data(status, count, options)
      end
    end
  end

  def send_search_error_logs_metrics
    namespace = "SearchErrorLogs/#{Rails.env}"
    duration = {created_at: 10.minutes.ago..Time.zone.now}

    SearchErrorLog.where(duration).where.not(device_type: 'crawler').where(user_id: -1).group(:location).count.each do |location, count|
      options = {namespace: namespace, dimensions: [{name: 'Sign in', value: 'false'}, {name: 'Duration', value: '10 minutes'}]}
      put_metric_data(location, count, options)
    end

    SearchErrorLog.where(duration).where.not(device_type: 'crawler').where.not(user_id: -1).group(:location).count.each do |location, count|
      options = {namespace: namespace, dimensions: [{name: 'Sign in', value: 'true'}, {name: 'Duration', value: '10 minutes'}]}
      put_metric_data(location, count, options)
    end
  end

  def send_twitter_users_metrics
    namespace = "TwitterUsers#{"/#{Rails.env}" unless Rails.env.production?}"
    duration = {created_at: 10.minutes.ago..Time.zone.now}

    [
        [TwitterUser.where(duration).where(user_id: -1), false],
        [TwitterUser.where(duration).where.not(user_id: -1), true]
    ].each do |records, signed_in|
      options = {namespace: namespace, dimensions: [{name: 'Sign in', value: signed_in.to_s}, {name: 'Duration', value: '10 minutes'}]}
      records_count = records.size
      unique_count = records.map(&:uid).uniq.size

      if records_count != unique_count
        put_metric_data('UniqueRecordsDiff', records_count - unique_count, options)
      end

      if records_count > 0
        put_metric_data('RecordsCreationCount', records_count, options)
        put_metric_data('MaxFriendsCount', records.map(&:friends_count).max, options)
        put_metric_data('MaxFollowersCount', records.map(&:followers_count).max, options)
      end
    end
  end

  def send_create_twitter_user_logs_metrics
    namespace = "CreateTwitterUserLogs/#{Rails.env}"
    duration = {created_at: 10.minutes.ago..Time.zone.now}

    CreateTwitterUserLog.where(duration).where(user_id: -1).where.not(error_class: nil).group(:error_class).count.each do |key, count|
      name = key.demodulize
      options = {namespace: namespace, dimensions: [{name: 'Sign in', value: 'false'}, {name: 'Duration', value: '10 minutes'}]}
      put_metric_data(name, count, options)
    end

    CreateTwitterUserLog.where(duration).where.not(user_id: -1).where.not(error_class: nil).group(:error_class).count.each do |key, count|
      name = key.demodulize
      options = {namespace: namespace, dimensions: [{name: 'Sign in', value: 'true'}, {name: 'Duration', value: '10 minutes'}]}
      put_metric_data(name, count, options)
    end
  end

  def send_twitter_db_users_metrics
    namespace = "TwitterDBUsers#{"/#{Rails.env}" unless Rails.env.production?}"
    options = {namespace: namespace, dimensions: [{name: 'Duration', value: '10 minutes'}]}

    duration = {created_at: 10.minutes.ago..Time.zone.now}
    put_metric_data('RecordsCreateCount', TwitterDB::User.where(duration).size, options)

    duration = {updated_at: 10.minutes.ago..Time.zone.now}
    put_metric_data('RecordsUpdateCount', TwitterDB::User.where(duration).size, options)
  end

  def send_search_histories_metrics
    namespace = "SearchHistories#{"/#{Rails.env}" unless Rails.env.production?}"
    duration = {created_at: 10.minutes.ago..Time.zone.now}

    #[
    #    [SearchHistory.where(duration).where(user_id: -1), false],
    #    [SearchHistory.where(duration).where.not(user_id: -1), true]
    #].each do |records, signed_in|
    #  key = signed_in ? :user_id : :session_id
    #  avg = records.size / records.map{|r| r.send(key) }.uniq.size rescue nil
    #  if avg
    #    options = {namespace: namespace, dimensions: [{name: 'Sign in', value: signed_in.to_s}, {name: 'Duration', value: '10 minutes'}]}
    #    put_metric_data('AvgSearchHistoriesCount', avg, options)
    #  end
    #
    #  max = records.each_with_object(Hash.new(0)) { |record, memo| memo[record.send(key)] += 1 }.values.max
    #  options = {namespace: namespace, dimensions: [{name: 'Sign in', value: signed_in.to_s}, {name: 'Duration', value: '10 minutes'}]}
    #  put_metric_data('MaxSearchHistoriesCount', max, options)
    #
    #  records.group_by(&:via).map { |k, v| [k.blank? ? 'EMPTY' : k, v.length] }.each do |via, count|
    #    next if count < 2
    #    options = {namespace: namespace, dimensions: [{name: 'Sign in', value: signed_in.to_s}, {name: 'Duration', value: '10 minutes'}]}
    #    put_metric_data("via(#{via})", count, options)
    #  end
    #end
  end

  def send_sign_in_logs_metrics
    namespace = "SignInLogs#{"/#{Rails.env}" unless Rails.env.production?}"
    duration = {created_at: 10.minutes.ago..Time.zone.now}

    #[
    #    [SignInLog.where(duration).where(context: 'create'), :create],
    #    #[SignInLog.where(duration).where(context: 'update'), :update],
    #].each do |records, context|
    #  records.group_by(&:via).map { |k, v| [k.blank? ? 'EMPTY' : k, v.length] }.each do |via, count|
    #    #next if count < 2
    #    options = {namespace: namespace, dimensions: [{name: 'Context', value: context.to_s}, {name: 'Duration', value: '10 minutes'}]}
    #    put_metric_data("#{via}", count, options)
    #  end
    #end
  end

  def send_requests_metrics
    namespace = "Requests#{"/#{Rails.env}" unless Rails.env.production?}"
    duration = {created_at: 10.minutes.ago..Time.zone.now}

    [
        CreatePromptReportRequest,
        CreateTwitterUserRequest,
        DeleteTweetsRequest,
        FollowRequest,
        ImportTwitterUserRequest,
        ResetCacheRequest,
        ResetEgotterRequest,
        TweetRequest,
        UnfollowRequest,
    ].each do |klass|
      finished_count = klass.where(duration).where.not(finished_at: nil).count
      options = {namespace: namespace, dimensions: [{name: 'Class', value: klass.to_s}, {name: 'Finished', value: 'true'}, {name: 'Duration', value: '10 minutes'}]}
      put_metric_data('FinishCount', finished_count, options) if finished_count > 0

      unfinished_count = klass.where(duration).where(finished_at: nil).count
      options = {namespace: namespace, dimensions: [{name: 'Class', value: klass.to_s}, {name: 'Finished', value: 'false'}, {name: 'Duration', value: '10 minutes'}]}
      put_metric_data('NotFinishedCount', unfinished_count, options) if unfinished_count > 0
    end
  end

  def send_bots_metrics
    namespace = "Bots#{"/#{Rails.env}" unless Rails.env.production?}"

    count = Bot.where(authorized: false).size
    options = {namespace: namespace, dimensions: []}
    put_metric_data('UnauthorizedCount', count, options) if count > 0
  end

  private

  def client
    @client ||= CloudWatchClient::Metrics.new
  end

  def put_metric_data(*args)
    client.append(*args)
  end

  # It is not working
  def encode(str)
    options = {
        invalid: :replace,
        undef: :replace,
        replace: '',
        universal_newline: true
    }
    str.encode(Encoding.find('ASCII'), options)
  end
end
