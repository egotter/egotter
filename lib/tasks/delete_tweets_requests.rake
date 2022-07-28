namespace :delete_tweets_requests do
  task consume_scheduled_jobs: :environment do
    limit = ENV['LIMIT']&.to_i || 10
    DeleteTweetWorker.consume_scheduled_jobs(limit: limit)
  end
end
