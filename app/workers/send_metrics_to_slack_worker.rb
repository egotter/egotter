class SendMetricsToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

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
          :send_prompt_report_metrics,
          :send_prompt_report_error_metrics,
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
    [
        [User, Visitor],
        [SearchLog, SearchErrorLog],
        SignInLog,
        TwitterUser,
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
            memo[klass.to_s] = klass.where(created_at: 1.hour.ago..Time.zone.now).size
          end

      stats = stats.sort_by {|k, _| k}.to_h
      SlackClient.send_message(SlackClient.format(stats), channel: SlackClient::TABLE_MONITORING)
    end
  end

  def send_user_metrics
    stats = {
        first_access: User.where(first_access_at: 1.hour.ago..Time.zone.now).size,
        last_access: User.where(last_access_at: 1.hour.ago..Time.zone.now).size
    }

    SlackClient.send_message(SlackClient.format(stats))
  end

  def send_twitter_user_metrics
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
    stats = {'rt:activeUsers' => GoogleAnalyticsClient.new.active_users}
    SlackClient.send_message(SlackClient.format(stats))
  end

  def send_prompt_report_metrics
    condition = {created_at: 1.hour.ago..Time.zone.now}
    stats = {
        prompt_reports: PromptReport.where(condition).size,
        'prompt_reports(read)' => PromptReport.where(condition.merge(read_at: 1.hour.ago..Time.zone.now)).size,
        create_prompt_report_logs: CreatePromptReportLog.where(condition).size,
    }

    SlackClient.send_message(SlackClient.format(stats), channel: SlackClient::MESSAGING_MONITORING)
  end

  def send_prompt_report_error_metrics
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
    queues = Sidekiq::Queue.all.select {|queue| queue.latency > 0}.sort_by(&:name)
    queues = queues.map do |queue|
      [queue.name, {size: queue.size, latency: sprintf("%.3f", queue.latency)}]
    end.to_h
    SlackClient.send_message(SlackClient.format(queues), channel: SlackClient::SIDEKIQ_MONITORING)
  end

  def send_sidekiq_worker_metrics(types = nil)
    unless types
      types = Rails.env.development? ? %w(sidekiq_all) : %w(sidekiq sidekiq_misc sidekiq_import sidekiq_prompt_reports)
    end

    types.each do |type|
      stats = SidekiqStats.new(type).to_a.sort_by {|k, _| k}.to_h
      SlackClient.send_message(SlackClient.format(stats), channel: SlackClient::SIDEKIQ_MONITORING)
    end
  end

  def send_nginx_metrics
    stats = NginxStats.new
    SlackClient.send_message(SlackClient.format(stats))
  end

  def send_search_histories_metrics
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

    SlackClient.send_message(SlackClient.format(stats))
  end

  def divide(num1, num2)
    num1 / num2
  rescue ZeroDivisionError => e
    0
  end
end
