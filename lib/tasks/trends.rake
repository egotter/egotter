namespace :trends do
  task save_latest_trends: :environment do |task|
    logger = TaskLogger.logger
    logger.info "task=#{task.name} start"

    trends = Trend.fetch_trends
    Trend.import trends
    logger.info "task=#{task.name} import=#{trends.size}"
    logger.info "task=#{task.name} finish"
  end

  task update_trend_insights: :environment do |task|
    logger = TaskLogger.logger
    logger.info "task=#{task.name} start"

    num = ENV['NUM']&.to_i || 3
    min_tweets = ENV['MIN_TWEETS']&.to_i || 1000
    max_tweets = ENV['MAX_TWEETS']&.to_i || 50000

    Trend.japan.latest_trends.top_n(num).where(created_at: 5.minutes.ago..Time.zone.now).each do |trend|
      next unless trend.tweets_size.nil?

      # if tweets.size < min_tweets
      #   tweets = trend.search_tweets(options.merge(since: nil, _until: nil))
      # end

      size = trend.replace_tweets(count: max_tweets)

      logger.info "task=#{task.name} name=#{trend.name} tweets=#{size}"
    end

    logger.info "task=#{task.name} finish"
  end

  task search_tweets: :environment do |task|
    logger = TaskLogger.logger
    logger.info "task=#{task.name} start"

    trend = Trend.find(ENV['TREND_ID'])
    max_tweets = ENV['MAX_TWEETS']&.to_i || 50000

    size = trend.replace_tweets(count: max_tweets)

    logger.info "task=#{task.name} name=#{trend.name} tweets=#{size}"
    logger.info "task=#{task.name} finish"
  end
end
