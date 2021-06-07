namespace :deletable_tweets do
  task delete: :environment do
    dry_run = ENV['DRY_RUN']
    since_time = 7.days.ago
    deleted_count = 0

    DeletableTweet.select(:id).where('created_at < ?', since_time).find_in_batches do |tweets|
      ids = tweets.map(&:id)
      DeletableTweet.where(id: ids).delete_all unless dry_run
      deleted_count += ids.size
    end

    puts deleted_count
  end
end
