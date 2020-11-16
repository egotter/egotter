namespace :trends do
  task save_latest_trends: :environment do |task|
    logger = TaskLogger.logger

    trends = Trend.fetch_trends
    Trend.import trends
    logger.info "task=#{task.name} import=#{trends.size}"

    Trend.japan.latest_trends.top_n(3).where(created_at: 5.minutes.ago..Time.zone.now).each do |trend|
      if trend.tweets_size.nil?
        tweets = trend.search_tweets(count: 10000)
        trend.import_tweets(tweets, update_words_count: true, update_times_count: true)

        logger.info "task=#{task.name} name=#{trend.name} tweets=#{tweets.size}"
      end
    end
  end
end
