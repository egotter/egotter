namespace :twitter_db do
  namespace :users do
    task consume_scheduled_jobs: :environment do
      limit = ENV['LIMIT']&.to_i || 100
      ImportTwitterDBUserWorker.consume_scheduled_jobs(limit: limit)
    end
  end
end
