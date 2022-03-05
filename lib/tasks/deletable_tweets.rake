namespace :deletable_tweets do
  task delete: :environment do
    DeleteRecordsTask.new(DeletableTweet, ENV['YEAR'], ENV['MONTH']).start
  end
end
