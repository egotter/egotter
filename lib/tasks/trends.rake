namespace :trends do
  task save_latest_trends: :environment do
    trends = Trend.fetch_trends
    Trend.import trends

    Trend.japan.latest_trends.top_n(3).where(time: 1.minute.ago..Time.zone.now).each do |trend|
      if trend.tweets_size.nil?
        tweets = trend.search_tweets(count: 10000)
        trend.import_tweets(tweets)
        trend.update!(tweets_size: tweets.size, tweets_imported_at: Time.zone.now)
      end
    end
  end
end
