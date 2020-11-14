namespace :trends do
  task save_latest_trends: :environment do
    trends = Trend.fetch_trends
    Trend.import trends
  end
end
