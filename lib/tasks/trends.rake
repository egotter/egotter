namespace :trends do
  task save_latest_trends: :environment do |task|
    logger = TaskLogger.logger

    trends = Trend.fetch_trends
    Trend.import trends
    logger.info "task=#{task.name} import=#{trends.size}"

    client_loader = Proc.new do
      User.api_client.tap { |c| c.twitter.verify_credentials }
    rescue => e
      logger.info "Change client exception=#{e.inspect}"
      Bot.api_client
    end

    Trend.japan.latest_trends.top_n(3).where(created_at: 5.minutes.ago..Time.zone.now).each do |trend|
      if trend.tweets_size.nil?
        tweets = trend.search_tweets(count: 30000, client_loader: client_loader)
        if tweets.size < 1000
          tweets = trend.search_tweets(count: 30000, client_loader: client_loader, without_time: true)
        end
        trend.import_tweets(tweets)

        tweets.map(&:uid).uniq.each_slice(100) do |uids|
          CreateTwitterDBUserWorker.compress_and_perform_async(uids, enqueued_by: task.name)
        end

        logger.info "task=#{task.name} name=#{trend.name} tweets=#{tweets.size}"
      end
    end
  end
end
