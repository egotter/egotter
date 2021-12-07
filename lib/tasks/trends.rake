namespace :trends do
  task save: :environment do |task|
    max_id = Trend.maximum(:id)
    Trend.import Trend.fetch_trends

    client = User.admin.api_client.twitter

    Trend.japan.top_10.where('id > ?', max_id).limit(10).each do |trend|
      response = client.search(trend.name, count: 1, result_type: 'recent', include_entities: false)
      statuses = response.attrs[:statuses]
      next if statuses.empty?

      props = trend.properties || {}
      props[:tweet] = {id: statuses[0][:id], text: statuses[0][:text]}
      trend.update(properties: props)
    end
  end

  task update_trend_insights: :environment do |task|
    logger = TaskLogger.logger
    logger.info "task=#{task.name} start"

    num = ENV['TRENDS']&.to_i || 3
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

    max_tweets = ENV['MAX_TWEETS']&.to_i || 50000

    ids = ENV['TREND_ID'].split(',')
    Trend.where(id: ids).each do |trend|
      size = trend.replace_tweets(count: max_tweets, progress: true)
      logger.info "task=#{task.name} name=#{trend.name} tweets=#{size}"
    end
    logger.info "task=#{task.name} finish"
  end

  task update_profile_words_count: :environment do |task|
    logger = TaskLogger.logger
    logger.info "task=#{task.name} start"

    ids = ENV['TREND_ID'].split(',')
    Trend.where(id: ids).each do |trend|
      tweets = trend.imported_tweets
      trend.trend_insight.update_profile_words_count(tweets)
      logger.info "task=#{task.name} name=#{trend.name}"
    end
    logger.info "task=#{task.name} finish"
  end
end
