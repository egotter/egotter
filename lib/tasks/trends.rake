namespace :trends do
  task save_latest_trends: :environment do |task|
    logger = TaskLogger.logger

    trends = Trend.fetch_trends
    Trend.import trends
    logger.info "task=#{task.name} import=#{trends.size}"

    Trend.japan.latest_trends.top_n(3).where(created_at: 5.minutes.ago..Time.zone.now).each do |trend|
      if trend.tweets_size.nil?
        tweets = trend.search_tweets(count: 10000)
        trend.import_tweets(tweets)

        logger.info "task=#{task.name} name=#{trend.name} tweets=#{tweets.size}"

        begin
          words_count = Trend.words_count(tweets)
          trend.update(words_count: words_count)
        rescue => e
          logger.warn "task=#{task.name} #{e.inspect.truncate(100)} name=#{trend.name}"
        end

        begin
          times_count = Trend.times_count(tweets)
          trend.update(times_count: times_count)
        rescue => e
          logger.warn "task=#{task.name} #{e.inspect.truncate(100)} name=#{trend.name}"
        end
      end
    end
  end
end
