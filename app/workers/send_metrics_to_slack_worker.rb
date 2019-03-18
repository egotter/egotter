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

  def send_table_metrics
    SlackClient.send_message(__method__, channel: SlackClient::TABLE_MONITORING)

    condition = 1.hour.ago..Time.zone.now

    [
        [User, Visitor],
        [SearchLog, SearchErrorLog],
        SignInLog,
        TwitterUser,
        [TwitterDB::User, TwitterDB::Profile],
        SearchHistory,
        Job,
        [FollowRequest, UnfollowRequest],
        [ForbiddenUser, NotFoundUser, BlockedUser],
        [ResetEgotterRequest, ResetEgotterLog],
        [DeleteTweetsRequest, DeleteTweetsLog],
        [ResetCacheRequest, ResetCacheLog],
        Tokimeki::User,
    ].map do |klasses|
      klasses = [klasses] unless klasses.is_a?(Array)
      stats =
          klasses.each_with_object(Hash.new(0)) do |klass, memo|
            memo[klass.to_s] = klass.where(created_at: condition).size
          end

      stats = stats.sort_by {|k, _| k}.to_h
      SlackClient.send_message(SlackClient.format(stats), channel: SlackClient::TABLE_MONITORING)
    end
  end

  def send_user_metrics
    SlackClient.send_message(__method__)

    stats = {
        first_access: User.where(first_access_at: 1.hour.ago..Time.zone.now).size,
        last_access: User.where(last_access_at: 1.hour.ago..Time.zone.now).size
    }

    SlackClient.send_message(SlackClient.format(stats))
  end

  def send_twitter_user_metrics
    SlackClient.send_message(__method__)

    users = TwitterUser.where(created_at: 1.hour.ago..Time.zone.now)

    friends_count = []
    followers_count = []
    friends_size = []
    followers_size = []

    users.each do |user|
      friends_count << user.friends_count
      followers_count << user.followers_count
      friends_size << user.friends_size
      followers_size << user.followers_size
    end
    size = users.size

    stats = {
        size: size,
        creation_completed: users.creation_completed.size,
        friends_count: {
            avg: sprintf("%.1f", divide(friends_count.sum, size)),
            min: friends_count.min,
            max: friends_count.max
        },
        followers_count: {
            avg: sprintf("%.1f", divide(followers_count.sum, size)),
            min: followers_count.min,
            max: followers_count.max
        },
        friends_size: {
            avg: sprintf("%.1f", divide(friends_size.sum, size)),
            min: friends_size.min,
            max: friends_size.max
        },
        followers_size: {
            avg: sprintf("%.1f", divide(followers_size.sum, size)),
            min: followers_size.min,
            max: followers_size.max
        }
    }

    SlackClient.send_message(SlackClient.format(stats))
  end

  def send_google_analytics_metrics
    SlackClient.send_message(__method__)

    stats = {'rt:activeUsers' => GoogleAnalyticsClient.new.active_users}
    SlackClient.send_message(SlackClient.format(stats))
  end

  def send_prompt_report_metrics
    SlackClient.send_message(__method__, channel: SlackClient::MESSAGING_MONITORING)

    condition = {created_at: 1.hour.ago..Time.zone.now}
    stats = {
        prompt_reports: PromptReport.where(condition).size,
        'prompt_reports(read)' => PromptReport.where(condition.merge(read_at: 1.hour.ago..Time.zone.now)).size,
        create_prompt_report_logs: CreatePromptReportLog.where(condition).size,
    }

    SlackClient.send_message(SlackClient.format(stats), channel: SlackClient::MESSAGING_MONITORING)
  end

  def send_prompt_report_error_metrics
    SlackClient.send_message(__method__, channel: SlackClient::MESSAGING_MONITORING)

    condition = {created_at: 1.hour.ago..Time.zone.now}
    stats =
        CreatePromptReportLog.select('error_class, count(*) cnt').
            where(condition).
            group('error_class').
            order('cnt desc').map do |record|
          [record.error_class, record.cnt]
        end.to_h

    stats.transform_keys! do |key|
      if key.include?(':')
        key.split(':')[-1]
      elsif key.empty?
        'EMPTY'
      else
        key
      end
    end

    SlackClient.send_message(SlackClient.format(stats), channel: SlackClient::MESSAGING_MONITORING)
  end

  def send_sidekiq_queue_metrics
    SlackClient.send_message(__method__, channel: SlackClient::SIDEKIQ_MONITORING)

    queues = Sidekiq::Queue.all.select {|queue| queue.latency > 0}.sort_by(&:name)
    queues = queues.map do |queue|
      [queue.name, {size: queue.size, latency: sprintf("%.3f", queue.latency)}]
    end.to_h
    SlackClient.send_message(SlackClient.format(queues), channel: SlackClient::SIDEKIQ_MONITORING)
  end

  def send_sidekiq_worker_metrics(types = nil)
    SlackClient.send_message(__method__, channel: SlackClient::SIDEKIQ_MONITORING)

    unless types
      types = Rails.env.development? ? %w(sidekiq_all) : %w(sidekiq sidekiq_misc sidekiq_import sidekiq_prompt_reports)
    end

    types.each do |type|
      stats = SidekiqStats.new(type).to_a.sort_by {|k, _| k}.to_h
      SlackClient.send_message(SlackClient.format(stats), channel: SlackClient::SIDEKIQ_MONITORING)
    end
  end

  def send_nginx_metrics
    SlackClient.send_message(__method__)

    stats = NginxStats.new
    SlackClient.send_message(SlackClient.format(stats))
  end

  def send_search_histories_metrics
    SlackClient.send_message(__method__)

    histories = SearchHistory.where(created_at: 1.hour.ago..Time.zone.now)

    stats =
        histories.each_with_object(Hash.new(0)).each do |his, memo|
          memo[his.source] += 1
        end

    stats = stats.sort_by {|_, v| -v}.to_h
    SlackClient.send_message(SlackClient.format(stats))
  end

  def send_visitors_metrics
    condition = {created_at: 1.hour.ago..Time.zone.now}
    visitors = Visitor.where(condition)

    stats =
        visitors.each_with_object(Hash.new(0)) do |v, memo|
          key = [
              v.user_found? ? 'user' : 'visitor',
              v.search_history_found? ? 'search' : 'not',
              v.source,

          ].join('/')
          memo[key] += 1
        end

    %w(visitor/not/ visitor/search/ user/not/ user/search/).each do |prefix|
      stat = stats.select {|k, _| k.start_with?(prefix)}.transform_keys {|k| k.remove(prefix)}
      stat = stat.sort_by {|_, v| -v}.to_h

      SlackClient.send_message("#{__method__} (#{prefix})", channel: SlackClient::VISITORS_MONITORING)
      SlackClient.send_message(SlackClient.format(stat), channel: SlackClient::VISITORS_MONITORING)
    end
  end

  def send_sign_in_metrics
    logs = SignInLog.where(created_at: 1.hour.ago..Time.zone.now)

    %w(create update).each do |context|
      stats =
          logs.select {|log| log.context == context}.each_with_object(Hash.new(0)).each do |log, memo|
            memo[log.via] += 1
          end

      stats = stats.sort_by {|_, v| -v}.to_h

      SlackClient.send_message("#{__method__} (#{context})", channel: SlackClient::SIGN_IN_MONITORING)
      SlackClient.send_message(SlackClient.format(stats), channel: SlackClient::SIGN_IN_MONITORING)
    end
  end

  def send_rate_limit_metrics
    SlackClient.send_message(__method__, channel: SlackClient::RATE_LIMIT_MONITORING)

    stats =
        Bot.rate_limit.map do |limit|
          id = limit.delete(:id).to_s
          values = limit.map {|key, value| [key, value[:remaining]]}.to_h
          [id, values]
        end.to_h

    SlackClient.send_message(SlackClient.format(stats), channel: SlackClient::RATE_LIMIT_MONITORING)
  end

  def send_search_error_metrics
    logs = SearchErrorLog.where(created_at: 1.hour.ago..Time.zone.now).
        where.not(device_type: 'crawler').
        where.not(session_id: '-1')

    stats =
        logs.each_with_object(Hash.new(0)).each do |log, memo|
          memo["#{log.user_found? ? 'user' : 'visitor'}/#{log.location}/#{log.source}"] += 1
        end

    %w(visitor/ user/).each do |prefix|
      stat = stats.select {|k, _| k.start_with?(prefix)}.transform_keys {|k| k.remove(prefix)}
      stat = stat.sort_by {|_, v| -v}.to_h

      SlackClient.send_message("#{__method__} (#{prefix})", channel: SlackClient::SEARCH_ERROR_MONITORING)
      SlackClient.send_message(SlackClient.format(stat), channel: SlackClient::SEARCH_ERROR_MONITORING)
    end
  end

  def divide(num1, num2)
    num1 / num2
  rescue ZeroDivisionError => e
    0
  end
end
